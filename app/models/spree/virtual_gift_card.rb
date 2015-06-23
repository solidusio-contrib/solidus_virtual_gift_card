class Spree::VirtualGiftCard < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to :store_credit, class_name: 'Spree::StoreCredit'
  belongs_to :purchaser, class_name: 'Spree::User'
  belongs_to :redeemer, class_name: 'Spree::User'
  belongs_to :line_item, class_name: 'Spree::LineItem'
  before_create :set_redemption_code, unless: -> { redemption_code }


  validates :amount, numericality: { greater_than: 0 }
  validates_uniqueness_of :redemption_code, conditions: -> { where(redeemed_at: nil) }
  validates_presence_of :purchaser_id

  scope :unredeemed, -> { where(redeemed_at: nil) }
  scope :by_redemption_code, -> (redemption_code) { where(redemption_code: redemption_code) }

  def redeemed?
    redeemed_at.present?
  end

  def redeem(redeemer)
    return false if redeemed?
    create_store_credit!({
      amount: amount,
      currency: currency,
      memo: memo,
      user: redeemer,
      created_by: redeemer,
      action_originator: self,
      category: store_credit_category,
    })
    self.update_attributes( redeemed_at: Time.now, redeemer: redeemer )
  end

  def memo
    "Gift Card ##{self.redemption_code}"
  end

  def formatted_redemption_code
    redemption_code.scan(/.{4}/).join('-')
  end

  def formatted_amount
    number_to_currency(amount, precision: 0)
  end

  def store_credit_category
    Spree::StoreCreditCategory.where(name: Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME).first
  end

  def self.active_by_redemption_code(redemption_code)
    Spree::VirtualGiftCard.unredeemed.by_redemption_code(redemption_code).first
  end

  private

  def set_redemption_code
    self.redemption_code = generate_unique_redemption_code
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
