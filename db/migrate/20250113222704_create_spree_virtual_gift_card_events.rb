class CreateSpreeVirtualGiftCardEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_virtual_gift_card_events do |t|
      t.integer "virtual_gift_card_id", null: false
      t.string "action", limit: 255, null: false
      t.decimal "amount", precision: 8, scale: 2
      t.string "authorization_code", limit: 255, null: false
      t.datetime "deleted_at", precision: nil
      t.decimal "user_total_amount", precision: 8, scale: 2, default: "0.0", null: false
      t.integer "originator_id"
      t.string "originator_type", limit: 255
      t.decimal "amount_remaining", precision: 8, scale: 2
      t.index ["virtual_gift_card_id"], name: "index_spree_virtual_gift_card_events_on_virtual_gift_card_id"

      t.timestamps
    end
  end
end
