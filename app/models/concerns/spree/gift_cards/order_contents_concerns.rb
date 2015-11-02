module Spree
  module GiftCards::OrderContentsConcerns
    extend ActiveSupport::Concern
    class GiftCardDateFormatError < StandardError; end

    included do
      prepend(InstanceMethods)
    end

    module InstanceMethods
      def add(variant, quantity = 1, options = {})
        line_item = super
        create_gift_cards(line_item, quantity, options["gift_card_details"] || {})
        line_item
      end

      def remove(variant, quantity = 1, options = {})
        line_item = super
        remove_gift_cards(line_item, quantity)
        line_item
      end

      def update_cart(params)
        update_success = super(params)

        if update_success && params[:line_items_attributes]
          line_item = Spree::LineItem.find_by(id: params[:line_items_attributes][:id])
          new_quantity = params[:line_items_attributes][:quantity].to_i
          update_gift_cards(line_item, new_quantity)
        end

        update_success
      end

      private

      def create_gift_cards(line_item, quantity_diff, gift_card_details = {})
        if line_item.gift_card?
          quantity_diff.to_i.times do
            Spree::VirtualGiftCard.create!(
              amount: line_item.price,
              currency: line_item.currency,
              line_item: line_item,
              recipient_name: gift_card_details["recipient_name"],
              recipient_email: gift_card_details["recipient_email"],
              purchaser_name: gift_card_details["purchaser_name"],
              gift_message: gift_card_details["gift_message"],
              send_email_at: format_date(gift_card_details["send_email_at"])
            )
          end
        end
      end

      def remove_gift_cards(line_item, quantity_diff)
        if line_item.gift_card?
          line_item.gift_cards.order(:created_at).last(quantity_diff).each(&:destroy!)
        end
      end

      def update_gift_cards(line_item, new_quantity)
        if line_item && line_item.gift_card?
          gift_card_count = line_item.gift_cards.count
          if new_quantity > gift_card_count
            create_gift_cards(line_item, new_quantity - gift_card_count)
          elsif new_quantity < line_item.gift_cards.count
            remove_gift_cards(line_item, gift_card_count - new_quantity)
          end
        end
      end

      def format_date(date)
        return date if date.acts_like?(:date) || date.acts_like?(:time)
        return Date.today if date.nil?

        begin
          Date.parse(date)
        rescue ArgumentError
          raise GiftCardDateFormatError
        end
      end
    end
  end
end

