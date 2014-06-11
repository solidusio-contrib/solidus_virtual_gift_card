module SpreeStoreCredits::ApiUsersControllerDecorator
  def store_credit_history
    @store_credit_events = user.try(:store_credit_events)
  end
end

Spree::Api::UsersController.prepend SpreeStoreCredits::ApiUsersControllerDecorator
