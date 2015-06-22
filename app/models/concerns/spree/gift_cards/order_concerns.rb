module Spree
  module GiftCards::OrderConcerns
    extend ActiveSupport::Concern

    included do
      Spree::Order.state_machine.after_transition to: :complete, do: :send_gift_card_emails

      has_many :gift_cards, through: :line_items

      prepend(InstanceMethods)
    end

    module InstanceMethods
      def finalize!
        create_gift_cards
        super
      end

      def create_gift_cards
        line_items.each do |item|
          item.quantity.times do
            Spree::VirtualGiftCard.create!(amount: item.price, currency: item.currency, purchaser: user, line_item: item) if item.gift_card?
          end
        end
      end

      def send_gift_card_emails
        gift_cards.each do |gift_card|
          Spree::GiftCardMailer.gift_card_email(gift_card).deliver
        end
      end
    end
  end
end
