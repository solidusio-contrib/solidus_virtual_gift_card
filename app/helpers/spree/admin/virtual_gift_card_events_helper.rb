# frozen_string_literal: true

module Spree
  module Admin
    module VirtualGiftCardEventsHelper
      mattr_accessor :originator_links
      self.originator_links = {
        Spree::Payment.to_s => {
          new_tab: true,
          href_type: :payment,
          translation_key: 'admin.gift_cards.payment_originator'
        },
        Spree::Refund.to_s => {
          new_tab: true,
          href_type: :payments,
          translation_key: 'admin.gift_cards.refund_originator'
        }
      }

      def gift_card_event_admin_action_name(gift_card_event)
        if Spree::VirtualGiftCardEvent::NON_EXPOSED_ACTIONS.include?(gift_card_event.action) ||
           gift_card_event.action == Spree::VirtualGiftCard::VOID_ACTION
          t("spree.virtual_gift_card.display_action.admin.#{gift_card_event.action}")
        else
          gift_card_event.display_action
        end
      end

      def gift_card_event_originator_link(gift_card_event)
        originator = gift_card_event.originator
        return unless originator

        add_user_originator_link
        unless originator_links.key?(gift_card_event.originator.class.to_s)
          raise "Unexpected originator type #{originator.class}"
        end

        options = {}
        link_options = originator_links[gift_card_event.originator.class.to_s]
        options[:target] = '_blank' if link_options[:new_tab]

        # Although not all href_types are used in originator_links
        # they are necessary because they may be used within extensions
        case link_options[:href_type]
        when :user
          link_to(
            t(link_options[:translation_key], email: originator.email, scope: 'spree'),
            spree.edit_admin_user_path(originator),
            options
          )
        when :line_item
          order = originator.line_item.order
          link_to(
            t(link_options[:translation_key], order_number: order.number, scope: 'spree'),
            spree.edit_admin_order_path(order),
            options
          )
        when :payment
          order = originator.order
          link_to(
            t(link_options[:translation_key], order_number: order.number, scope: 'spree'),
            spree.admin_order_payment_path(order, originator),
            options
          )
        when :payments
          order = originator.payment.order
          link_to(
            t(link_options[:translation_key], order_number: order.number, scope: 'spree'),
            spree.admin_order_payments_path(order),
            options
          )
        end
      end

      private

      # Cannot set the value for a user originator
      # because Spree.user_class is not defined at that time.
      # Spree::UserClassHandle does not work here either as
      # the assignment is evaluated before user_class is set
      def add_user_originator_link
        originator_links[Spree.user_class.to_s] = {
          new_tab: true,
          href_type: :user,
          translation_key: 'admin.gift_cards.user_originator'
        }
      end
    end
  end
end
