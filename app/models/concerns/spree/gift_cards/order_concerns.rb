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
        gift_card_options = options["gift_card_details"]
        !line_item.gift_card? ||
          (line_item.gift_card? && gift_card_options.present? &&
          line_item.gift_cards.any? {|gc| gc.recipient_email == gift_card_options['recipient_email']} &&
          line_item.gift_cards.any? {|gc| gc.recipient_name == gift_card_options['recipient_name']} &&
          line_item.gift_cards.any? {|gc| gc.purchaser_name == gift_card_options['purchaser_name']} &&
          line_item.gift_cards.any? {|gc| gc.gift_message == gift_card_options['gift_message']})
      end

      def finalize!
        gift_cards.each do |gift_card|
          gift_card.make_redeemable!(purchaser: user)
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
