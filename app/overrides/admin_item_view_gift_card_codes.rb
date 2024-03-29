# frozen_string_literal: true

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
