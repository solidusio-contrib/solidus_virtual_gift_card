class AddFieldsToVirtualGiftCard < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_virtual_gift_cards, :amount_used, :decimal, default: "0.0"
    add_column :spree_virtual_gift_cards, :amount_authorized, :decimal, default: "0.0"
  end
end
