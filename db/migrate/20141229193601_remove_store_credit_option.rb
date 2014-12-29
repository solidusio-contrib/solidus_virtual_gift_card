class RemoveStoreCreditOption < ActiveRecord::Migration
  def up
    store_credit = Spree::PaymentMethod.find_by(type: "Spree::PaymentMethod::StoreCredit")
    store_credit.update_attribute(:display_on, "front_end") if store_credit
  end

  def down
    store_credit = Spree::PaymentMethod.find_by(type: "Spree::PaymentMethod::StoreCredit")
    store_credit.update_attribute(:display_on, nil) if store_credit
  end
end
