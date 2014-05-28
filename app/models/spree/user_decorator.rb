module Spree::UserDecorator
  extend ActiveSupport::Concern

  included do
    has_many :store_credits

    prepend(InstanceMethods)
  end

  module InstanceMethods
    def total_available_store_credit
      store_credits.to_a.sum{ |credit| credit.amount_remaining }
    end
  end
end

Spree::User.include(Spree::UserDecorator)
