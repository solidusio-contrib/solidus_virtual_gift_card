class AddEmailSendTimeToVirtualGiftCard < ActiveRecord::Migration
  def change
    add_column :spree_virtual_gift_cards, :send_email_at, :date
    add_column :spree_virtual_gift_cards, :sent_at, :datetime
    add_index :spree_virtual_gift_cards, :send_email_at
  end
end
