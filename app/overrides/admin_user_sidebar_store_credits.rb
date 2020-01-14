# frozen_string_literal: true

Deface::Override.new(
  virtual_path: 'spree/admin/users/_tabs',
  name: 'admin_user_sidebar_store_credits',
  insert_bottom: "[data-hook='admin_user_tab_options']",
  partial: 'spree/admin/users/gift_card_tabs'
)
