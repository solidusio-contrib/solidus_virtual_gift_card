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
        !(line_item.gift_card? && options["gift_card_details"])
      end

      def finalize!
        gift_cards.each do |gift_card|
          gift_card.make_redeemable!
        end

        super
      end

      def send_gift_card_emails
        gift_cards.each do |gift_card|
          Spree::GiftCardMailer.gift_card_email(gift_card).deliver
        end
      end
    end
  end
end
