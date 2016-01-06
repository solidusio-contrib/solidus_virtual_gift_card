class AddDeactivatedAtToGiftCard < ActiveRecord::Migration
  def change
    add_column :spree_virtual_gift_cards, :deactivated_at, :datetime
  end
end
