class Spree::StoreCredit < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user
  belongs_to :category, class_name: "Spree::StoreCreditCategory"
  belongs_to :created_by, class_name: "Spree::User"

  validates_presence_of :user, :category, :created_by
  validates_numericality_of :amount, { greater_than: 0 }
  validates_numericality_of :amount_used, { greater_than_or_equal_to: 0 }
  validate :amount_used_less_than_or_equal_to_amount

  delegate :name, to: :category, prefix: true
  delegate :email, to: :created_by, prefix: true

  def display_amount
    Spree::Money.new(amount)
  end

  def display_amount_used
    Spree::Money.new(amount_used)
  end

  private

  def amount_used_less_than_or_equal_to_amount
    return true if amount_used.nil?

    if amount_used > amount
      errors.add(:amount_used, Spree.t('admin.store_credits.errors.amount_used_cannot_be_greater'))
    end
  end

end
