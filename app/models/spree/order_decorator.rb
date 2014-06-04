module SpreeStoreCredits::OrderDecorator
  extend ActiveSupport::Concern

  included do
    Spree::Order.state_machine.before_transition to: :confirm, do: :add_store_credit_payments

    prepend(InstanceMethods)
  end

  module InstanceMethods
    def add_store_credit_payments
      payments.store_credits.where(state: 'checkout').map(&:invalidate!)
      return if user.nil? || user.store_credits.empty?

      payment_method = Spree::PaymentMethod.find_by_type('Spree::PaymentMethod::StoreCredit')

      remaining_total = outstanding_balance
      user.store_credits.each do |credit|
        next if credit.amount_remaining.zero?

        amount_to_take = [credit.amount_remaining, remaining_total].min
        payments.create!(source: credit,
                         payment_method: payment_method,
                         amount: amount_to_take,
                         uncaptured_amount: amount_to_take,
                         state: 'checkout',
                         response_code: credit.generate_authorization_code)
        remaining_total -= amount_to_take

        break if remaining_total.zero?
      end
    end

    def covered_by_store_credit?
      return false unless user
      user.total_available_store_credit >= total
    end
    alias_method :covered_by_store_credit, :covered_by_store_credit?

    def total_available_store_credit
      return 0.0 unless user
      user.total_available_store_credit
    end

    def order_total_after_store_credit
      total - total_applicable_store_credit
    end

    def total_applicable_store_credit
      if confirm? || complete?
        payments.store_credits.valid.sum(:amount)
      else
        [total, (user.try(:total_available_store_credit) || 0.0)].min
      end
    end

    def display_total_applicable_store_credit
      Spree::Money.new(-total_applicable_store_credit, { currency: currency })
    end

    def display_order_total_after_store_credit
      Spree::Money.new(order_total_after_store_credit, { currency: currency })
    end

    def display_total_available_store_credit
      Spree::Money.new(total_available_store_credit, { currency: currency })
    end

    def display_store_credit_remaining_after_capture
      Spree::Money.new(total_available_store_credit - total_applicable_store_credit, { currency: currency })
    end
  end
end

Spree::Order.include SpreeStoreCredits::OrderDecorator
