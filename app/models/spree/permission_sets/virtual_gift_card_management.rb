# frozen_string_literal: true

module Spree
  module PermissionSets
    class VirtualGiftCardManagement < PermissionSets::Base
      def activate!
        can :manage, Spree::VirtualGiftCard
      end
    end
  end
end
