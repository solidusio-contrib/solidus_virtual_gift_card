class Spree::StoreCredit < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user
  belongs_to :category, class_name: "Spree::StoreCreditCategory"
  belongs_to :created_by, class_name: "Spree::User"
  belongs_to :credit_type, class_name: 'Spree::StoreCreditType', :foreign_key => 'type_id'
  has_many :store_credit_events

  validates_presence_of :user, :category, :created_by
  validates_numericality_of :amount, { greater_than: 0 }
  validates_numericality_of :amount_used, { greater_than_or_equal_to: 0 }
  validate :amount_used_less_than_or_equal_to_amount
  validate :amount_authorized_less_than_or_equal_to_amount
  validates_presence_of :credit_type

  delegate :name, to: :category, prefix: true
  delegate :email, to: :created_by, prefix: true

  scope :order_by_priority, -> { includes(:credit_type).order('spree_store_credit_types.priority ASC') }
  scope :chronological, -> { order("spree_store_credits.created_at DESC") }

  before_validation :associate_credit_type

  def display_amount
    Spree::Money.new(amount)
  end

  def display_amount_used
    Spree::Money.new(amount_used)
  end

  def amount_remaining
    amount - amount_used - amount_authorized
  end

  def authorize(amount, order_currency, authorization_code = generate_authorization_code)
    if validate_authorization(amount, order_currency)
      update_attributes(amount_authorized: self.amount_authorized + amount)

      event = self.store_credit_events.create!(action: 'authorize', amount: amount, authorization_code: authorization_code)
      event.authorization_code
    else
      errors.add(:base, Spree.t('store_credit_payment_method.insufficient_authorized_amount'))
      false
    end
  end

  def validate_authorization(amount, order_currency)
    if amount_remaining < amount
      errors.add(:base, Spree.t('store_credit_payment_method.insufficient_funds'))
    elsif currency != order_currency
      errors.add(:base, Spree.t('store_credit_payment_method.currency_mismatch'))
    end
    return errors.blank?
  end

  def capture(amount, authorization_code, order_currency)
    return false unless authorize(amount, order_currency, authorization_code)

    if amount <= amount_authorized
      if currency != order_currency
        errors.add(:base, Spree.t('store_credit_payment_method.currency_mismatch'))
        false
      else
        self.update_attributes!(amount_used: self.amount_used + amount, amount_authorized: self.amount_authorized - amount)
        event = self.store_credit_events.create!(action: 'capture', amount: amount, authorization_code: authorization_code)
        event.authorization_code
      end
    else
      errors.add(:base, Spree.t('store_credit_payment_method.insufficient_authorized_amount'))
      false
    end
  end

  def void(authorization_code)
    if capture_event = store_credit_events.find_by(action: 'capture', authorization_code: authorization_code)
      return_amount = capture_event.amount

      self.update_attributes!(amount_used: amount_used - capture_event.amount)
      self.store_credit_events.create!(action: 'void', amount: capture_event.amount, authorization_code: authorization_code)
      true
    elsif auth_event = store_credit_events.find_by(action: 'authorize', authorization_code: authorization_code)
      self.update_attributes!(amount_authorized: amount_authorized - auth_event.amount)
      self.store_credit_events.create!(action: 'void', amount: auth_event.amount, authorization_code: authorization_code)
      true
    else
      errors.add(:base, Spree.t('store_credit_payment_method.unable_to_void', auth_code: authorization_code))
      false
    end
  end

  def credit(amount, authorization_code, order_currency)
    # Find the amount related to this authorization_code in order to add the store credit back
    capture_event = store_credit_events.find_by(action: 'capture', authorization_code: authorization_code)

    if currency != order_currency  # sanity check to make sure the order currency hasn't changed since the auth
      errors.add(:base, Spree.t('store_credit_payment_method.currency_mismatch'))
      false
    elsif capture_event && amount <= capture_event.amount
      self.update_attributes!(amount_used: amount_used - amount)
      self.store_credit_events.create!(action: 'credit', amount: amount, authorization_code: authorization_code)
      true
    else
      errors.add(:base, Spree.t('store_credit_payment_method.unable_to_credit', auth_code: authorization_code))
      false
    end
  end

  def amount_used
    self.read_attribute(:amount_used) || 0
  end

  def amount_authorized
    self.read_attribute(:amount_authorized) || 0
  end

  def actions
    %w{capture void credit}
  end

  def can_capture?(payment)
    payment.pending? || payment.checkout?
  end

  def can_void?(payment)
    payment.pending? || payment.completed?
  end

  def can_credit?(payment)
    return false unless payment.completed?
    return false unless payment.order.payment_state == 'credit_owed'
    payment.credit_allowed > 0
  end

  def generate_authorization_code
    "#{self.id}-SC-#{Time.now.utc.strftime("%Y%m%d%H%M%S%6N")}"
  end

  private

  def amount_used_less_than_or_equal_to_amount
    return true if amount_used.nil?

    if amount_used > amount
      errors.add(:amount_used, Spree.t('admin.store_credits.errors.amount_used_cannot_be_greater'))
    end
  end

  def amount_authorized_less_than_or_equal_to_amount
    if (amount_used + amount_authorized) > amount
      errors.add(:amount_authorized, Spree.t('admin.store_credits.errors.amount_authorized_exceeds_total_credit'))
    end
  end

  def associate_credit_type
    self.credit_type = Spree::StoreCreditType.find_by_name(Spree::StoreCreditType::DEFAULT_TYPE_NAME) unless self.credit_type
  end
end
