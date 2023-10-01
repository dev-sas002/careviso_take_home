Rails.application.routes.draw do
  get 'select_optimal_packages', to: 'package_selectors#select_optimal_packages'
  resources :products
  resources :orders
  resources :packages

  root to: redirect('/products')
  match '*path', to: 'application#not_found', via: :all
end
