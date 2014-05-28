FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'spree_store_credits/factories'
  #

  factory :store_credit, class: Spree::StoreCredit do
    user             { create(:user) }
    created_by       { create(:user) }
    category         { create(:store_credit_category) }
    amount           { 150.00 }
  end

  factory :store_credit_category, class: Spree::StoreCreditCategory do
    name             "Exchange"
  end
end
