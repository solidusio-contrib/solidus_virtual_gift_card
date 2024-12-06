# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.class_eval do
          state_machine.after_transition to: :complete, do: :send_gift_card_emails

          has_many :gift_cards, through: :line_items
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

      def complete!
        super
        inventory_units = self.inventory_units
        gift_cards.each_with_index do |gift_card, index|
          gift_card.make_redeemable!(purchaser: user, inventory_unit: inventory_units[index])
        end
      end

      def send_gift_card_emails
        gift_cards.each do |gift_card|
          if gift_card.send_email_at.nil? || gift_card.send_email_at <= DateTime.now
            gift_card.send_email
          end
        end
      end

      ::Spree::Order.prepend self
    end
  end
end
