module Spree
  module GiftCards::InventoryUnitConcerns
    extend ActiveSupport::Concern

    included do
      has_one :gift_card, class_name: 'Spree::VirtualGiftCard'
    end
  end
end

