# frozen_string_literal: true

class SetRedeemableTrueOnVirtualGiftCards < SolidusSupport::Migration[4.2]
  def up
    Spree::VirtualGiftCard.find_each do |gift_card|
      gift_card.update!(redeemable: true)
    end
  end

  def down
    # noop
  end
end
