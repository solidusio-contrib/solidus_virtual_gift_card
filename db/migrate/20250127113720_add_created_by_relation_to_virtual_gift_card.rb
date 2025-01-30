class AddCreatedByRelationToVirtualGiftCard < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_virtual_gift_cards, :created_by, type: :integer, null: true, foreign_key: { to_table: Spree.user_class.table_name }
  end
end
