module SpreeStoreCredits::PaymentMethodDecorator
  extend ActiveSupport::Concern

  included do
    prepend(InstanceMethods)
  end

  module InstanceMethods
    def store_credit?
      self.class == Spree::PaymentMethod::StoreCredit
    end
  end
end

Spree::PaymentMethod.include SpreeStoreCredits::PaymentMethodDecorator
