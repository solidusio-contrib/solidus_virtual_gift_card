module Spree
  module GiftCards::OrderConcerns
    extend ActiveSupport::Concern

    included do
      Spree::Order.state_machine.after_transition to: :complete, do: :send_gift_card_emails

      has_many :gift_cards, through: :line_items

      prepend(InstanceMethods)
    end

    module InstanceMethods
      def gift_card_match(line_item, options)
        return true unless line_item.gift_card?
        line_item.gift_cards.any? do |gift_card|
          gc_detail_set = gift_card.details.stringify_keys.except("send_email_at").to_set
          options_set = options["gift_card_details"].except("send_email_at").to_set
          gc_detail_set.superset?(options_set)
        end
      end

      def finalize!
        super
        gift_cards.each do |gift_card|
          gift_card.make_redeemable!(purchaser: user)
        end
      end

      def send_gift_card_emails
        gift_cards.each do |gift_card|
          if gift_card.send_email_at.nil? || gift_card.send_email_at <= DateTime.now
            gift_card.send_email
          end
        end
      end
    end
  end
end
