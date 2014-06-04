module SpreeStoreCredits::ApiCheckoutsControllerDecorator
  private

  def object_params
    # For payment step, filter order parameters to produce the expected nested attributes for a single payment and its source, discarding attributes for payment methods other than the one selected
    # respond_to check is necessary due to issue described in #2910
    object_params = nested_params
    if @order.has_checkout_step?('payment') && @order.payment?
      if object_params[:payments_attributes].is_a?(Hash)
        object_params[:payments_attributes] = [object_params[:payments_attributes]]
      end
      if object_params[:payment_source].present? && source_params = object_params.delete(:payment_source)[object_params[:payments_attributes].first[:payment_method_id]]
        object_params[:payments_attributes].first[:source_attributes] = source_params
      end
      #if object_params[:payments_attributes]
        #object_params[:payments_attributes].first[:amount] = @order.total.to_s
      #end
    end
    object_params
  end
end

Spree::Api::CheckoutsController.prepend SpreeStoreCredits::ApiCheckoutsControllerDecorator
