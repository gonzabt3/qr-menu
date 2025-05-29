Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  get '/ping', to: 'ping#index' # Ruta para el endpoint de ping
  get 'check_first_login', to: 'users#check_first_login'
  get 'menus/by_name/:name', to: 'menus#show_by_name', as: 'menus_by_name'
  get 'menus/by_restaurant_id/:id', to: 'menus#show_by_restaurant_id', as: 'menus_by_restaurant_id'

  resources :users, only: %i[create update] do
    post 'subscribe', to: 'users#subscribe', on: :member, constraints: { id: /.*/ }
    post 'unsubscribe', to: 'users#unsubscribe', on: :member, constraints: { id: /.*/ }
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
        collection do
          patch :reorder # Ruta para reordenar las secciones
        end
      end
    end
  end

  namespace :api do
    post 'mercado_pago', to: 'mercado_pago#info'
  end
end
