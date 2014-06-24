class Spree::VirtualGiftCard < ActiveRecord::Base
  belongs_to :store_credit, class_name: 'Spree::StoreCredit'
  belongs_to :purchaser, class_name: 'Spree::User'
  belongs_to :redeemer, class_name: 'Spree::User'
  before_create :set_redemption_code

  validates :amount, numericality: { greater_than: 0 }
  validates_uniqueness_of :redemption_code, conditions: -> { where(redeemed_at: nil) }

  def redeemed?
    redeemed_at.present?
  end

  def redeem!(redeemer)
    return false if redeemed?
    self.build_store_credit(amount: self.amount, currency: self.currency, memo: self.memo, user: redeemer, created_by: redeemer, category: self.store_credit_category).save
    self.update_attributes( redeemed_at: Time.now, redeemer: redeemer )
  end

  def memo
    "Gift Card ##{self.redemption_code}"
  end

  def store_credit_category
    Spree::StoreCreditCategory.where(name: Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME).first
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
    Spree::VirtualGiftCard.where(redemption_code: redemption_code).where(redeemed_at: nil).present?
  end
end
