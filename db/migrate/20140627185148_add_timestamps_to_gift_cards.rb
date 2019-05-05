class AddTimestampsToGiftCards < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :created_at, :datetime
    add_column :spree_virtual_gift_cards, :updated_at, :datetime
  end
end
