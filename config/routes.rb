# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :gift_cards, only: [:index, :edit, :update]

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

  concern :order_routes do
    resources :line_items
    resources :payments do
      member do
        put :authorize
        put :capture
        put :purchase
        put :void
        put :credit
      end
    end

    resources :addresses, only: [:show, :update]

    resources :return_authorizations do
      member do
        put :cancel
      end
    end

    resources :customer_returns, except: :destroy
  end

  namespace :api, defaults: { format: 'json' } do
    resources :gift_cards, only: [] do
      collection do
        post :redeem
      end
    end

    resources :orders, concerns: :order_routes do
      member do
        put :cancel
        put :empty
      end

      resources :coupon_codes, only: [:create, :destroy]
      resources :gift_card_codes, only: [:create, :destroy]
    end
  end
end
