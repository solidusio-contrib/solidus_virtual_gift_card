module Spree::UserDecorator
  extend ActiveSupport::Concern

  included do
    has_many :store_credits
  end
end

Spree::User.include(Spree::UserDecorator)
