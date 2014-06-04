module Spree
  class StoreCreditEvent < ActiveRecord::Base
    belongs_to :store_credit
  end
end
