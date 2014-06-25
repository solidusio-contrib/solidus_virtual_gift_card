Deface::Override.new(
  virtual_path: "spree/admin/shared/_menu",
  name: "admin_user_sub_menu_index",
  insert_after: "#admin-menu",
  partial: "spree/admin/users/sub_menu",
)
