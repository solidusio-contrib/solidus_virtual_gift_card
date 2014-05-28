module SpreeStoreCredits::PaymentDecorator
  extend ActiveSupport::Concern

  included do
    delegate :store_credit?, to: :payment_method
    scope :store_credits, -> { where(source_type: Spree::StoreCredit.to_s) }
    after_create :create_eligible_credit_event
    prepend(InstanceMethods)
  end

  module InstanceMethods
    private

    def create_eligible_credit_event
      return unless store_credit?
      source.store_credit_events.create!(action: 'eligible',
                                         amount: amount,
                                         authorization_code: response_code)
    end

    def invalidate_old_payments
      order.payments.with_state('checkout').where("id != ?", self.id).where(source_type: self.source_type).each do |payment|
        payment.invalidate! unless payment.store_credit?
      end
    end
  end
end

Spree::Payment.include SpreeStoreCredits::PaymentDecorator
