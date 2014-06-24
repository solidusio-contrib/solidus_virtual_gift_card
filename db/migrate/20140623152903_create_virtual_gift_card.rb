class CreateVirtualGiftCard < ActiveRecord::Migration
  def change
    create_table :spree_virtual_gift_cards do |t|
      t.integer :purchaser_id
      t.integer :redeemer_id
      t.integer :store_credit_id
      t.integer :amount
      t.string :currency
      t.string :redemption_code
      t.datetime :redeemed_at
    end

    add_index :spree_virtual_gift_cards, :redemption_code
    add_index :spree_virtual_gift_cards, :redeemed_at
  end
end
