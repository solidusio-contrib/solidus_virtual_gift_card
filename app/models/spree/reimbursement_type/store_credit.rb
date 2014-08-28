class Spree::ReimbursementType::StoreCredit < Spree::ReimbursementType
  extend Spree::ReimbursementType::ReimbursementHelpers

  class << self
    def reimburse(reimbursement, return_items, simulate)
      unpaid_amount = return_items.sum(&:total).round(2)
      payments = store_credit_payments(reimbursement)
      reimbursement_list = []

      # Credit each store credit that was used on the order
      reimbursement_list, unpaid_amount = create_refunds(reimbursement, payments, unpaid_amount, simulate, reimbursement_list)

      # If there is any amount left to pay out to the customer, then create credit with that amount
      if unpaid_amount > 0.0
        reimbursement_list, unpaid_amount = create_credits(reimbursement, unpaid_amount, simulate, reimbursement_list)
      end

      reimbursement_list
    end

    private

    def create_creditable(reimbursement, unpaid_amount)
      category = Spree::StoreCreditCategory.default_reimbursement_category(category_options(reimbursement))
      Spree::StoreCredit.new(user: reimbursement.order.user, amount: unpaid_amount, category: category, created_by: Spree::StoreCredit.default_created_by, memo: "Refund for uncreditable payments on order #{reimbursement.order.number}", currency: reimbursement.order.currency)
    end

    def store_credit_payments(reimbursement)
      reimbursement.order.payments.completed.store_credits
    end

    # overwrite if you need options for the default reimbursement category
    def category_options(reimbursement)
      {}
    end
  end
end
