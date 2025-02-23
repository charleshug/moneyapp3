Rails.application.routes.draw do
  get "home/index"

  resources :import_trxes, only: [] do
    collection do
      post :submit_import
      post :import_preview
    end
  end

  post "trxes/:id/add_line", to: "trxes#add_line", as: :add_line_to_trx  # For existing transactions
  post "trxes/add_line",     to: "trxes#add_line", as: :add_line_to_new_trx   # For new transactions

  resources :trxes, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :add_line_to_trx
    end
    collection do
      post :add_line_to_new_trx
    end
  end

  get "/trxes_export", to: "trxes_export#create"

  resources :accounts
  resources :ledgers
  resources :vendors
  resources :categories
  resources :subcategories

  resources :budgets do
    member do
      post "set_current"
    end
  end

  post "update_budget_values", to: "budgets#update_budgets"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  get "reports", to: "reports#net_worth", as: "reports"
  get "reports/income_expense", to: "reports#income_expense", as: "income_expense_reports"
  get "reports/net_worth", to: "reports#net_worth", as: "net_worth_reports"
  get "reports/vendor", to: "reports#spending_by_vendor", as: "vendor_reports"
  get "reports/category", to: "reports#spending_by_category", as: "category_reports"

  root "accounts#index"
end
