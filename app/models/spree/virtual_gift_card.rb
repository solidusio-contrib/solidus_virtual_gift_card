# frozen_string_literal: true

class Spree::VirtualGiftCard < Spree::Base
  include ActiveSupport::NumberHelper

  VOID_ACTION       = 'void'
  CREDIT_ACTION     = 'credit'
  CAPTURE_ACTION    = 'capture'
  ELIGIBLE_ACTION   = 'eligible'
  AUTHORIZE_ACTION  = 'authorize'
  ALLOCATION_ACTION = 'allocation'
  ADJUSTMENT_ACTION = 'adjustment'
  INVALIDATE_ACTION = 'invalidate'

  attr_accessor :action, :action_amount, :action_originator, :action_authorization_code

  belongs_to :store_credit, class_name: 'Spree::StoreCredit', optional: true
  belongs_to :purchaser, class_name: Spree::UserClassHandle.new, optional: true
  belongs_to :redeemer, class_name: Spree::UserClassHandle.new, optional: true
  belongs_to :line_item, class_name: 'Spree::LineItem', optional: true
  belongs_to :inventory_unit, class_name: 'Spree::InventoryUnit', optional: true
  has_one :order, through: :line_item
  has_many :events, class_name: 'Spree::VirtualGiftCardEvent', dependent: :destroy

  validates :amount, numericality: { greater_than: 0 }
  validates :redemption_code, uniqueness: { conditions: -> { where(redeemed_at: nil, redeemable: true) } }
  validates :purchaser_id, presence: { if: proc { |gc| gc.redeemable? } }

  scope :unredeemed, -> { where(redeemed_at: nil) }
  scope :by_redemption_code, ->(redemption_code) { where(redemption_code: redemption_code) }
  scope :purchased, -> { where(redeemable: true) }

  after_save :store_event

  def self.ransackable_associations(_auth_object = nil)
    %w[line_item order]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[redemption_code recipient_email sent_at send_email_at]
  end

  ransacker :sent_at do
    Arel.sql('date(sent_at)')
  end

  def redeemed?
    redeemed_at.present?
  end

  def deactivated?
    deactivated_at.present?
  end

  def redeem(redeemer)
    return false if redeemed? || !redeemable?

    create_store_credit!(
      amount: amount,
      currency: currency,
      memo: memo,
      user: redeemer,
      created_by: redeemer,
      action_originator: self,
      category: store_credit_category,
    )
    update( redeemed_at: Time.zone.now, redeemer: redeemer )
  end

  def make_redeemable!(purchaser:, inventory_unit:)
    update!(redeemable: true, purchaser: purchaser, inventory_unit: inventory_unit, redemption_code: redemption_code || generate_unique_redemption_code)
  end

  def deactivate
    update(redeemable: false, deactivated_at: Time.zone.now) &&
      cancel_and_reimburse_inventory_unit
  end

  def can_deactivate?
    order.completed? && order.paid? && !deactivated?
  end

  def memo
    "Gift Card ##{redemption_code}"
  end

  def details
    {
      amount: formatted_amount,
      redemption_code: formatted_redemption_code,
      recipient_email: recipient_email,
      recipient_name: recipient_name,
      purchaser_name: purchaser_name,
      gift_message: gift_message,
      send_email_at: send_email_at,
      formatted_send_email_at: formatted_send_email_at
    }
  end

  def formatted_redemption_code
    redemption_code.present? ? redemption_code.scan(/.{4}/).join('-') : ''
  end

  def formatted_amount
    number_to_currency(amount, precision: 0)
  end

  def formatted_send_email_at
    send_email_at&.strftime('%-m/%-d/%y')
  end

  def formatted_sent_at
    sent_at&.strftime('%-m/%-d/%y')
  end

  def formatted_created_at
    created_at.localtime.strftime('%F %I:%M%p')
  end

  def formatted_redeemed_at
    redeemed_at&.localtime&.strftime('%F %I:%M%p')
  end

  def formatted_deactivated_at
    deactivated_at&.localtime&.strftime('%F %I:%M%p')
  end

  def store_credit_category
    Spree::StoreCreditCategory.where(name: Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME).first
  end

  def self.active_by_redemption_code(redemption_code)
    Spree::VirtualGiftCard.unredeemed.by_redemption_code(redemption_code).first
  end

  def send_email
    Spree::GiftCardMailer.gift_card_email(self).deliver_later
    update!(sent_at: DateTime.now)
  end

  def generate_authorization_code
    [
      id,
      'GC',
      Time.current.utc.strftime('%Y%m%d%H%M%S%6N'),
      SecureRandom.uuid
    ].join('-')
  end

  def amount_remaining
    return 0.0.to_d if deactivated?
    amount - amount_used - amount_authorized
  end

  def deactivated?
    !!deactivated_at
  end

  def authorize(amount, order_currency, options = {})
    authorization_code = options[:action_authorization_code]
    if authorization_code
      if events.find_by(action: AUTHORIZE_ACTION, authorization_code:)
        # Don't authorize again on capture
        return true
      end
    else
      authorization_code = generate_authorization_code
    end

    if validate_authorization(amount, order_currency)
      update!({
        action: AUTHORIZE_ACTION,
        action_amount: amount,
        action_originator: options[:action_originator],
        action_authorization_code: authorization_code,

        amount_authorized: amount_authorized + amount
      })
      authorization_code
    else
      false
    end
  end

  def validate_authorization(amount, order_currency)
    if amount_remaining.to_d < amount.to_d
      errors.add(:base, I18n.t('spree.virtual_gift_card.insufficient_funds'))
    elsif currency != order_currency
      errors.add(:base, I18n.t('spree.virtual_gift_card.currency_mismatch'))
    end
    errors.blank?
  end

  def capture(amount, authorization_code, order_currency, options = {})
    return false unless authorize(amount, order_currency, action_authorization_code: authorization_code)
    auth_event = events.find_by!(action: AUTHORIZE_ACTION, authorization_code:)

    if amount <= auth_event.amount
      if currency != order_currency
        errors.add(:base, I18n.t('spree.virtual_gift_card.currency_mismatch'))
        false
      else
        update!({
          action: CAPTURE_ACTION,
          action_amount: amount,
          action_originator: options[:action_originator],
          action_authorization_code: authorization_code,

          amount_used: amount_used + amount,
          amount_authorized: amount_authorized - auth_event.amount
        })
        authorization_code
      end
    else
      errors.add(:base, I18n.t('spree.virtual_gift_card.insufficient_authorized_amount'))
      false
    end
  end

  private

  def store_event
    return unless saved_change_to_amount? || saved_change_to_amount_used? || saved_change_to_amount_authorized? || [ELIGIBLE_ACTION, INVALIDATE_ACTION].include?(action)

    event = if action
      events.build(action:)
    else
      events.where(action: ALLOCATION_ACTION).first_or_initialize
    end

    event.update!({
      amount: action_amount || amount,
      authorization_code: action_authorization_code || event.authorization_code || generate_authorization_code,
      amount_remaining:,
      originator: action_originator
    })
  end

  def cancel_and_reimburse_inventory_unit
    cancellation = Spree::OrderCancellations.new(line_item.order)
    cancellation.cancel_unit(inventory_unit)
    !!cancellation.reimburse_units([inventory_unit], created_by: purchaser)
  end

  def generate_unique_redemption_code
    redemption_code = Spree::RedemptionCodeGenerator.generate_redemption_code

    if duplicate_redemption_code?(redemption_code)
      generate_unique_redemption_code
    else
      redemption_code
    end
  end

  def duplicate_redemption_code?(redemption_code)
    Spree::VirtualGiftCard.active_by_redemption_code(redemption_code)
  end
end
