class BackfillGiftCardLineItems < ActiveRecord::Migration
  def up
    gc_variant_ids = Spree::Product.where(gift_card: true).flat_map(&:variants).flat_map(&:id)

    Spree::LineItem.joins(:order).where(variant_id: gc_variant_ids, spree_orders: { completed_at: nil } ).find_each do |line_item|
      if line_item.gift_cards.count != line_item.quantity
        line_item.order.contents.send(:update_gift_cards, line_item, line_item.quantity)
        say "Updated line item #{line_item.id} with #{line_item.quantity} quantity to have #{line_item.gift_cards.count} gift cards"
      end
    end
  end

  def down
    # No-op
  end
end