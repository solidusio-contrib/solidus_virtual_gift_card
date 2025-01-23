class AddGiftCardCodesToSpreeOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_orders, :gift_card_codes, :text
  end
end
