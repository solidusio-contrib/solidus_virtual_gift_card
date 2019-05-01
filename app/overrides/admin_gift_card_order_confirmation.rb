Deface::Override.new(
  virtual_path: 'spree/admin/orders/_order_details',
  name: 'add_gift_cards_to_admin_order_confirmation',
  insert_before: '#order-total',
  partial: 'spree/admin/orders/confirmation_gift_card_details',
)
