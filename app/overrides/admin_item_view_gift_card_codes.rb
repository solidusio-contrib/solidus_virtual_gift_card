Deface::Override.new(
  virtual_path: "spree/admin/orders/_shipment_manifest",
  name: "admin_item_view_gift_card_codes",
  insert_bottom: ".item-name",
  partial: "spree/admin/orders/gift_card_redemption_codes",
)

Deface::Override.new(
  virtual_path: "spree/admin/orders/_carton_manifest",
  name: "admin_item_view_gift_card_codes",
  insert_bottom: ".item-name",
  partial: "spree/admin/orders/gift_card_redemption_codes",
)
