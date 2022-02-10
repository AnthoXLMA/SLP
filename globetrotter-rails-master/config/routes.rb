# frozen_string_literal: true

Rails.application.routes.draw do
  scope "(:locale)", locale: /en|fr/ do
    devise_for :users, controllers: { registrations: 'user/registrations' }

    resources :tours do
      resources :events, shallow: true, only: %i[show new create destroy]
      collection do
        get 'events'
      end
    end
    resources :comments, only: %i[create update destroy]
    resources :event_registrations, only: %i[index create destroy] do
      member do
        get 'after_event'
        get 'tip'
        post 'pay'
        get 'after_pay'
      end
    end
    resources :guides, only: %i[index show edit update new create destroy]
    resources :guide_events, only: %i[index show]

    get 'welcome', to: 'welcome#index'
    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
    root 'welcome#index'
  end
end
