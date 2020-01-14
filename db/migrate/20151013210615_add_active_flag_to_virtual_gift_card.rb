# frozen_string_literal: true

class AddActiveFlagToVirtualGiftCard < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_virtual_gift_cards, :redeemable, :boolean, default: false
  end
end
