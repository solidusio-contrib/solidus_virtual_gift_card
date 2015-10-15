class SetRedeemableTrueOnVirtualGiftCards < ActiveRecord::Migration
  def up
    Spree::VirtualGiftCard.find_each do |gift_card|
      gift_card.update_attributes!(redeemable: true)
    end
  end

  def down
    #noop
  end
end
