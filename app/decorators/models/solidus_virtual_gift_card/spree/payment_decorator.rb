# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module PaymentDecorator
      def self.prepended(base)
        base.scope :gift_cards, -> { where(source_type: 'Spree::VirtualGiftCard') }
        base.scope :not_gift_cards, -> { where(arel_table[:source_type].not_eq('Spree::VirtualGiftCard').or(arel_table[:source_type].eq(nil))) }
      end

      def gift_card?
        payment_method.try(:gift_card?)
      end

      def expired?
        gift_card_event = source.events.last

        gift_card_event.present? && gift_card_event.expired?
      end

      def invalidate_old_payments
        return unless !store_credit? && !gift_card? && !['invalid', 'failed'].include?(state)

        order.payments.select { |payment|
          payment.state == 'checkout' && !payment.store_credit? && !payment.gift_card? && payment.id != id
        }.each(&:invalidate!)
      end

      ::Spree::Payment.prepend self
    end
  end
end
