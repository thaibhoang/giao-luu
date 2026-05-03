Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[new create]
  get "users/:id", to: "users#public_show", as: :public_user_profile
  resources :passwords, param: :token
  get "profile", to: "users#show", as: :profile
  get "profile/edit", to: "users#edit", as: :edit_profile
  patch "profile", to: "users#update"
  root "home#index"
  resources :listings, only: %i[index show new create edit update] do
    resources :registrations, only: %i[index create destroy] do
      member do
        put :checkin
        put :confirm
        put :accept
        put :reject
      end
    end
    resource :bookmark, only: %i[create destroy]
    resource :chat_room, only: %i[show]
    get :chat_token, on: :member
  end
  get "geocoding/lookup", to: "geocoding#lookup"
  get "map", to: "listings#map"
  get "my-listings", to: "listings#my", as: :my_listings
  get "my/bookmarks", to: "my/bookmarks#index", as: :my_bookmarks
  get "my/registrations", to: "my/registrations#index", as: :my_registrations
  get "empty-map", to: "pages#empty_map"
  get "error-page", to: "pages#error_page"
  get "policy", to: "pages#policy"

  namespace :admin do
    get "login", to: "sessions#new", as: :new_session
    resource :session, only: %i[create destroy], path: "session"
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :facebook_imports, only: %i[new create] do
      collection do
        post :confirm
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :listings, only: %i[show create] do
        collection do
          get :map
        end
      end
    end
  end

  namespace :internal do
    namespace :v1 do
      post "listings/import", to: "listings_imports#create"
    end
    post "chat_events", to: "chat_events#create"
  end

  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: :xml }

  # SEO location landing pages — đặt cuối để không shadow các route khác.
  # Ví dụ: /cau-long/ho-chi-minh, /pickleball/ha-noi
  get ":sport/:city_slug",
      to: "location_landing#show",
      as: :location_landing,
      constraints: {
        sport: /cau-long|pickleball/,
        city_slug: /[a-z0-9\-]+/
      }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
