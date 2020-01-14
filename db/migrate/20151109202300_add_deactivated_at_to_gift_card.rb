# frozen_string_literal: true

class AddDeactivatedAtToGiftCard < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :deactivated_at, :datetime
  end
end
