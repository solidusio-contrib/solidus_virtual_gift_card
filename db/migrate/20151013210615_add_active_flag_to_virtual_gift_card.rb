class AddActiveFlagToVirtualGiftCard < ActiveRecord::Migration
  def change
    add_column :spree_virtual_gift_cards, :redeemable, :boolean, default: false
  end
end
