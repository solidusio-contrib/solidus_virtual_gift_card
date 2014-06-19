class Spree::StoreCreditCategory < ActiveRecord::Base
  def non_expiring?
    Spree::StoreCredits::Configuration.non_expiring_credit_types.include?(name)
  end
end
