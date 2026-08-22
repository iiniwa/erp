Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health" => "health#show"

      namespace :auth do
        resource :session, only: %i[create show destroy], controller: "sessions"
        resource :qr_session, only: %i[create], controller: "qr_sessions"
        resource :password, only: %i[update], controller: "passwords"
      end

      resource :me, only: %i[show], controller: "me"

      resources :users, only: %i[index show create update destroy], param: :user_code do
        member do
          post :retire
        end
      end

      resources :addresses, only: %i[index show create update destroy], param: :address_id
      resources :address_categories, only: %i[index create]

      resources :permission_masters, only: %i[index create update destroy]
      resources :role_permissions, only: %i[index update]

      resource :system_setting, only: %i[show update], controller: "system_settings" do
        get "files/:field", action: :file, on: :member, as: :file
      end
    end
  end
end
