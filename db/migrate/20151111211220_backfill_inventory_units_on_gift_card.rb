class BackfillInventoryUnitsOnGiftCard < ActiveRecord::Migration
  def up
    gift_card_products = Spree::Product.where(gift_card: true)

    gift_card_products.find_each do |product|
      line_items = product.line_items

      line_items.find_each do |line_item|
        if line_item.order.completed? && !line_item.gift_cards.all? {|gc| gc.inventory_unit.present? }
          inventory_units = line_item.inventory_units

          line_item.gift_cards.each_with_index do |gift_card, i|
            inventory_unit = inventory_units[i]
            gift_card.update_attributes!(inventory_unit: inventory_unit)
            say "Updating gift card #{gift_card.id} to have inventory unit #{inventory_unit.id}"
          end
        else
          say "Skipping line_item #{line_item.id}. Order incomplete or gift cards associated to inventory units"
        end
      end
    end
  end

  def down
    Spree::VirtualGiftCard.update_all(inventory_unit_id: nil)
  end
end
