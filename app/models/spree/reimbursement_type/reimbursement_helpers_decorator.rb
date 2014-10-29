Spree::ReimbursementType::ReimbursementHelpers.module_eval do
  def create_creditable_with_store_credits_decoration(reimbursement, unpaid_amount)
    category = Spree::StoreCreditCategory.default_reimbursement_category(category_options(reimbursement))
    Spree::StoreCredit.new(user: reimbursement.order.user, amount: unpaid_amount, category: category, created_by: Spree::StoreCredit.default_created_by, memo: "Refund for uncreditable payments on order #{reimbursement.order.number}", currency: reimbursement.order.currency)
  end

  # overwrite if you need options for the default reimbursement category
  def category_options(reimbursement)
    {}
  end

  alias_method_chain :create_creditable, :store_credits_decoration
end
