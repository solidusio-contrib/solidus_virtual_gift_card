class AddActiveFlagToVirtualGiftCard < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :redeemable, :boolean, default: false
  end
end
