class CreateSpreeStoreCreditPaymentMethod < ActiveRecord::Migration
  def up
    Spree::PaymentMethod.create(type: "Spree::PaymentMethod::StoreCredit", name: "Store Credit", description: "Store credit.", active: true, environment: Rails.env)
  end
end
