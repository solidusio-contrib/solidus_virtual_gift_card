# frozen_string_literal: true

class AddLineItemToGiftCard < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :line_item_id, :integer

    add_index :spree_virtual_gift_cards, :line_item_id
  end
end
