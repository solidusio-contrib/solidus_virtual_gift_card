Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :users, only: [] do
      resources :store_credits
    end
  end

  namespace :api, defaults: { format: 'json' } do
    resources :users, only: [] do
      member do
        get :store_credit_history
      end
    end
  end
end
