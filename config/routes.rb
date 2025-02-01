Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  get '/ping', to: 'ping#index' # Ruta para el endpoint de ping
  get 'check_first_login', to: 'users#check_first_login'
  get 'menus/by_name/:name', to: 'menus#show_by_name', as: 'menus_by_name'

  resources :users, only: %i[create update] do
    get 'restaurants', to: 'restaurants#index_by_email', on: :member, constraints: { id: /.*/ }
  end
  resources :restaurants, only: %i[index show create update destroy] do
    resources :menus, only: %i[index show create update destroy] do
      member do
        put 'set_favorite'
      end
      get 'products', to: 'products#index_by_menu'
      resources :sections, only: %i[index show create update destroy] do
        resources :products, only: %i[index show create update destroy]
      end
    end
  end
end
