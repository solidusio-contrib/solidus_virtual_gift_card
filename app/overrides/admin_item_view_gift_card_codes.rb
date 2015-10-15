Deface::Override.new(
  virtual_path: "spree/admin/orders/_line_items",
  name: "add_gift_cards_to_admin_line_items",
  insert_bottom: ".line-item-name",
  partial: "spree/admin/orders/cart_gift_card_details",
)

Deface::Override.new(
  virtual_path: "spree/admin/orders/_shipment_manifest",
  name: "admin_item_view_gift_card_codes",
  insert_bottom: ".item-name",
  partial: "spree/admin/orders/shipments_gift_card_details",
)

Deface::Override.new(
  virtual_path: "spree/admin/orders/_carton_manifest",
  name: "admin_item_view_gift_card_codes",
  insert_bottom: ".item-name",
  partial: "spree/admin/orders/shipments_gift_card_details",
)
