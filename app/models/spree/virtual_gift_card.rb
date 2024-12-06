# frozen_string_literal: true

class Spree::VirtualGiftCard < Spree::Base
  include ActiveSupport::NumberHelper

  belongs_to :store_credit, class_name: 'Spree::StoreCredit', optional: true
  belongs_to :purchaser, class_name: Spree::UserClassHandle.new, optional: true
  belongs_to :redeemer, class_name: Spree::UserClassHandle.new, optional: true
  belongs_to :line_item, class_name: 'Spree::LineItem', optional: true
  belongs_to :inventory_unit, class_name: 'Spree::InventoryUnit', optional: true
  has_one :order, through: :line_item

  validates :amount, numericality: { greater_than: 0 }
  validates :redemption_code, uniqueness: { conditions: -> { where(redeemed_at: nil, redeemable: true) } }
  validates :purchaser_id, presence: { if: proc { |gc| gc.redeemable? } }

  scope :unredeemed, -> { where(redeemed_at: nil) }
  scope :by_redemption_code, ->(redemption_code) { where(redemption_code: redemption_code) }
  scope :purchased, -> { where(redeemable: true) }

  def self.ransackable_associations(auth_object = nil)
    %w[line_item order]
  end

  def self.ransackable_attributes(auth_object = nil)
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
    update!(redeemable: true, purchaser: purchaser, inventory_unit: inventory_unit, redemption_code: (redemption_code || generate_unique_redemption_code))
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

  private

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
