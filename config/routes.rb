Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :users, only: [] do
      resources :gift_cards, only: [] do
        collection do
          get :lookup
          post :redeem
        end
      end
      collection do
        resources :gift_cards, only: [:index]
      end
    end

    resources :orders, only: [] do
      resources :gift_cards, only: [:edit, :update] do
        member do
          put :send_email
          put :deactivate
        end
      end
    end
  end

  namespace :api, defaults: { format: 'json' } do
    resources :gift_cards, only: [] do
      collection do
        post :redeem
      end
    end
  end
end
