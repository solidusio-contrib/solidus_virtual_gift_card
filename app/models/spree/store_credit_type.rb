module Spree
  class StoreCreditType < ActiveRecord::Base
    DEFAULT_TYPE_NAME = 'Promotional'
    has_one :store_credit, class_name: 'Spree::StoreCredit'
  end
end
