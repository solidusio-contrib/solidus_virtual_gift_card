# frozen_string_literal: true

module SolidusVirtualGiftCard
  module AdminGiftCardOrderConfirmation
    Deface::Override.new(
      virtual_path: 'spree/admin/orders/_order_details',
      name: 'add_gift_cards_to_admin_order_confirmation',
      insert_before: "[data-hook='order_details_total']",
      partial: 'spree/admin/orders/confirmation_gift_card_details'
    )
  end
end
