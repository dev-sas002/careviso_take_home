Rails.application.routes.draw do
  # The exercise itself: the smallest set of packages that ships an order exactly.
  get 'select_optimal_packages', to: 'package_selectors#select_optimal_packages'

  # Container healthcheck (see Dockerfile).
  get 'health', to: 'health#show'
  resources :products
  resources :orders
  resources :packages

  root to: redirect('/products')
  match '*path', to: 'application#not_found', via: :all
end
