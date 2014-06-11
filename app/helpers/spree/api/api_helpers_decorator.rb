Spree::Api::ApiHelpers.module_eval do
  def store_credit_history_attributes
    [:display_amount, :display_user_total_amount, :display_action]
  end

  def order_attributes_with_store_credit_decoration
    order_attributes_without_store_credit_decoration | [:covered_by_store_credit, :display_total_applicable_store_credit, :order_total_after_store_credit, :display_order_total_after_store_credit, :total_applicable_store_credit, :display_total_available_store_credit, :display_store_credit_remaining_after_capture]
  end

  alias_method_chain :order_attributes, :store_credit_decoration
end
