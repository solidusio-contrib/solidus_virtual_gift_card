# frozen_string_literal: true

class SeedGiftCardCategory < SolidusSupport::Migration[4.2]
  def change
    Spree::StoreCreditCategory.find_or_create_by(name: 'Gift Card')
  end
end
