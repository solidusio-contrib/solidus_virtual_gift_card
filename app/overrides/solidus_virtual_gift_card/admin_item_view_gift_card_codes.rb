# frozen_string_literal: true

module SolidusVirtualGiftCard
  module AdminItemViewGiftCardCodes
    Deface::Override.new(
      virtual_path: 'spree/admin/orders/confirm/_shipment_manifest',
      name: 'add_gift_cards_to_admin_confirm',
      insert_bottom: '.item-name',
      partial: 'spree/admin/orders/shipments_gift_card_details',
    )

    Deface::Override.new(
      virtual_path: 'spree/admin/orders/_shipment_manifest',
      name: 'admin_item_view_gift_card_codes',
      insert_bottom: '.item-name',
      partial: 'spree/admin/orders/shipments_gift_card_details',
    )

    Deface::Override.new(
      virtual_path: 'spree/admin/orders/_carton_manifest',
      name: 'admin_item_view_gift_card_codes',
      insert_bottom: '.item-name',
      partial: 'spree/admin/orders/shipments_gift_card_details',
    )

    Deface::Override.new(
      virtual_path: 'spree/admin/adjustments/index',
      name: 'admin_gift_card_codes',
      insert_before: 'erb[silent]:contains("if @order.can_add_coupon? && can?(:update, @order)")',
      partial: 'spree/admin/adjustments/add_gift_card_code'
    )

    Deface::Override.new(
      virtual_path: 'spree/admin/shared/_order_summary',
      name: 'admin_order_summary_gift_card_codes',
      insert_before: 'dt[data-hook=\'admin_order_tab_total_title\']',
      partial: 'spree/admin/shared/order_summary/gift_card_codes'
    )
  end
end
