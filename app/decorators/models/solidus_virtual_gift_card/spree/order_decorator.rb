# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.class_eval do
          state_machine.after_transition to: :complete, do: :send_gift_card_emails
          state_machine.before_transition to: :confirm, do: :add_gift_card_payments

          has_many :gift_cards, through: :line_items
          has_many :valid_gift_card_payments, -> { gift_cards.valid }, inverse_of: :order, class_name: 'Spree::Payment', foreign_key: :order_id

          serialize :gift_card_codes, type: Array, coder: YAML
        end
      end

      def gift_card_match(line_item, options)
        return true unless line_item.gift_card?
        return true unless options['gift_card_details']

        line_item.gift_cards.any? do |gift_card|
          gc_detail_set = gift_card.details.stringify_keys.except('send_email_at').to_set
          options_set = options['gift_card_details'].except('send_email_at').to_set
          gc_detail_set.superset?(options_set)
        end
      end

      def finalize
        super
        inventory_units = self.inventory_units
        gift_cards.each_with_index do |gift_card, index|
          gift_card.make_redeemable!(purchaser: user, inventory_unit: inventory_units[index])
        end
      end

      def send_gift_card_emails
        return unless SolidusVirtualGiftCard.configuration.send_gift_card_emails

        gift_cards.each do |gift_card|
          if gift_card.send_email_at.nil? || gift_card.send_email_at <= DateTime.now
            gift_card.send_email
          end
        end
      end

      def add_gift_card_payments
        return if payments.gift_cards.checkout.empty? && matching_gift_cards.sum(&:amount_remaining).zero?

        payments.gift_cards.checkout.each(&:invalidate!)

        # this can happen when multiple payments are present, auto_capture is
        # turned off, and one of the payments fails when the user tries to
        # complete the order, which sends the order back to the 'payment' state.
        authorized_total = payments.pending.sum(:amount)

        remaining_total = outstanding_balance - authorized_total

        if matching_gift_cards.any?
          payment_method = ::Spree::PaymentMethod::GiftCard.first

          matching_gift_cards.each do |credit|
            break if remaining_total.zero?
            next if credit.amount_remaining.zero?

            amount_to_take = [credit.amount_remaining, remaining_total].min
            payments.create!(source: credit,
                             payment_method:,
                             amount: amount_to_take,
                             state: 'checkout',
                             response_code: credit.generate_authorization_code)
            remaining_total -= amount_to_take
          end
        end

        other_payments = payments.checkout.not_gift_cards
        if remaining_total.zero?
          other_payments.each(&:invalidate!)
        elsif other_payments.size == 1
          other_payments.first.update!(amount: remaining_total)
        end

        payments.reset

        if payments.where(state: %w(checkout pending completed)).sum(:amount) != total
          errors.add(:base, I18n.t('spree.virtual_gift_card.errors.unable_to_fund')) && (return false)
        end
      end

      def matching_gift_cards
        @matching_gift_cards = ::Spree::VirtualGiftCard
                               .where(currency:, redemption_code: gift_card_codes)
                               .sort_by do |virtual_gift_card|
                                 gift_card_codes.index(virtual_gift_card.redemption_code)
                               end
      end

      def format_redemption_codes_for_lookup
        gift_card_codes.map do |code|
          ::Spree::RedemptionCodeGenerator.format_redemption_code_for_lookup(code)
        end
      end

      def covered_by_gift_card?
        return false if matching_gift_cards.empty?

        matching_gift_cards.sum(&:amount_remaining) >= total
      end
      alias_method :covered_by_gift_card, :covered_by_gift_card?

      def order_total_after_gift_card
        total - total_applicable_gift_card
      end

      def total_applicable_gift_card
        if can_complete? || complete?
          valid_gift_card_payments.to_a.sum(&:amount)
        else
          [total, matching_gift_cards.sum(&:amount_remaining) || 0.0].min
        end
      end

      def display_total_applicable_gift_card
        ::Spree::Money.new(-total_applicable_gift_card, { currency: })
      end

      ::Spree::Order.prepend self
    end
  end
end
