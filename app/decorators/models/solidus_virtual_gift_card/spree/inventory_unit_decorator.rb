module SolidusVirtualGiftCard
  module Spree
    module InventoryUnitDecorator
      def self.prepended(base)
        base.class_eval do
          has_one :gift_card, class_name: 'Spree::VirtualGiftCard'
        end
      end

      ::Spree::InventoryUnit.prepend self
    end
  end
end
