module SpreeStoreCredits::PaymentDecorator
  extend ActiveSupport::Concern

  included do
    delegate :store_credit?, to: :payment_method
    scope :store_credits, -> { where(source_type: Spree::StoreCredit.to_s) }
    scope :not_store_credits, -> { where(arel_table[:source_type].not_eq(Spree::StoreCredit.to_s).or(arel_table[:source_type].eq(nil))) }
    after_create :create_eligible_credit_event
    prepend(InstanceMethods)
  end

  module InstanceMethods
    def cancel!
      if store_credit?
        credit!(amount)
      else
        super
      end
    end

    private

    def create_eligible_credit_event
      # When cancelling an order, a payment with the negative amount
      # of the payment total is created to refund the customer. That
      # payment has a source of itself (Spree::Payment) no matter the
      # type of payment getting refunded, hence the additional check
      # if the source is a store credit.
      return unless store_credit? && source.is_a?(Spree::StoreCredit)

      source.action = Spree::StoreCredit::ELIGIBLE_ACTION
      source.authorization_code = response_code
      source.action_amount = amount
      source.save! # creates the store credit event
    end

    def invalidate_old_payments
      return if store_credit? # store credits shouldn't invalidate other payment types
      order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
        payment.invalidate! unless payment.store_credit?
      end
    end
  end
end

Spree::Payment.include SpreeStoreCredits::PaymentDecorator
