module Spree
  module PermissionSets
    class VirtualGiftCardDisplay < PermissionSets::Base
      def activate!
        can [:display, :admin], Spree::VirtualGiftCard
      end
    end
  end
end
