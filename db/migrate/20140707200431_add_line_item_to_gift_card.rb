class AddLineItemToGiftCard < ActiveRecord::Migration
  def change
    add_column :spree_virtual_gift_cards, :line_item_id, :integer
  end
end
