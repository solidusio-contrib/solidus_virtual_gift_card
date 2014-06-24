class SeedGiftCardCategory < ActiveRecord::Migration
  def change
    Spree::StoreCreditCategory.find_or_create_by(name: 'Gift Card')
  end
end
