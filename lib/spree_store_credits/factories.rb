FactoryGirl.define do
  sequence(:store_credits_order_number)  { |n| "R1000#{n}" }
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
    currency         { "USD" }
  end

  factory :store_credit_category, class: Spree::StoreCreditCategory do
    name             "Exchange"
  end

  factory :store_credit_payment_method, class: Spree::PaymentMethod do
    type          "Spree::PaymentMethod::StoreCredit"
    name          "Store Credit"
    description   "Store Credit"
    active        true
    environment   "test"
    auto_capture  true
  end

  factory :store_credit_payment, class: Spree::Payment, parent: :payment do
    association(:payment_method, factory: :store_credit_payment_method)
    association(:source, factory: :store_credit)
  end

  factory :store_credit_auth_event, class: Spree::StoreCreditEvent do
    store_credit       { create(:store_credit) }
    action             { 'authorize' }
    amount             { 100.00 }
    authorization_code { "#{store_credit.id}-SC-20140602164814476128" }
  end

  factory :store_credits_order_without_user, class: Spree::Order do
    number             { generate(:store_credits_order_number) }
    bill_address
  end
end
