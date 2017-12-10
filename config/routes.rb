Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :product_imports, only: [:new, :create]
  end
end
