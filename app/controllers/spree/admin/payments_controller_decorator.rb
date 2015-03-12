module SpreeStoreCredits::AdminPaymentsControllerDecorator
  def self.prepended(base)
    base.before_action :load_user_store_credits, only: :new

    # TODO This action does not get hit by Bonobos because we made
    # the store credit payment method 'frontend_only'. If we ever want to enable
    # adding store credit payments via the admin manually, we will
    # need to change this to work with the changes here https://github.com/bonobos/spree/commit/8a133412eba6852593f5d8f03ca224a10746c2f2#diff-cf6c90cd69cad1243f7ba1dd062df744R22.
    # For now this is being disabled so that we can have green specs.
    # -AT 03/12/2015
    #
    # base.before_action :handle_store_credit_create, only: :create
  end

  def load_user_store_credits
    @store_credits = if @order.user
      @order.user.store_credits.reject { |store_credit| store_credit.amount_remaining.zero? }
    end
  end

  def handle_store_credit_create
    @payment = @order.payments.build(object_params)
    if @payment.store_credit?
      if store_credit_id = params["payment"]["store_credit_id"].presence
        store_credit = @order.user.store_credits.find(store_credit_id)
        amount = [ params[:payment][:amount].to_f,
                   store_credit.amount_remaining,
                   @order.outstanding_balance ].min

        auth_code = store_credit.generate_authorization_code
        @payment.assign_attributes(source: store_credit,
                                   amount: amount,
                                   response_code: auth_code)

      else
        flash[:error] = Spree.t("admin.store_credits.no_store_credit_selected")
        redirect_to spree.admin_order_payments_path(@order) and return false
      end
    end
  end
end

Spree::Admin::PaymentsController.prepend SpreeStoreCredits::AdminPaymentsControllerDecorator
