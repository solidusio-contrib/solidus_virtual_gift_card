class AddInventoryUnitToGiftCard < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :inventory_unit_id, :integer
  end
end
