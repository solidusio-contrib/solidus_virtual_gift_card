class AddGiftCardFlagToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :gift_card, :boolean, default: false
  end
end
