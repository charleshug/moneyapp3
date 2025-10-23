Rails.application.routes.draw do
  get "home/index"

  resources :import_trxes, only: [] do
    collection do
      get "import_preview"   # Redirect to import form
      post "import_preview"  # Handles the file upload and shows preview
      post "submit_import"   # Processes the final import
    end
  end

  post "trxes/:id/add_line", to: "trxes#add_line", as: :add_line_to_trx  # For existing transactions
  post "trxes/add_line",     to: "trxes#add_line", as: :add_line_to_new_trx   # For new transactions

  post "scheduled_trxes/:id/add_line", to: "scheduled_trxes#add_scheduled_line_to_scheduled_trx", as: :add_scheduled_line_to_scheduled_trx  # For existing transactions
  post "scheduled_trxes/add_line",     to: "scheduled_trxes#add_scheduled_line_to_new_scheduled_trx", as: :add_scheduled_line_to_new_scheduled_trx   # For new transactions

  resources :trxes, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :add_line_to_trx
      post :toggle_cleared
    end
    collection do
      post :add_line_to_new_trx
      post "import_preview"
      post "submit_import"
      get "import"
      get "balance_info"
    end
  end

  post "/trxes_export", to: "trxes_export#create"

  resources :accounts, except: [ :show ]
  resources :ledgers do
    member do
      post :toggle_carry_forward
      patch :update_budget
    end
    collection do
      post :rebuild_chains
      post :create_budget
    end
  end
  resources :vendors do
    collection do
      get :search
    end
  end
  resources :categories do
    collection do
      post :sort
    end
  end

  get "subcategories", to: redirect("/categories")
  resources :subcategories, except: [ :index ] do
    collection do
      post :sort
    end
  end

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

  root "trxes#index"

  resources :scheduled_trxes do
    collection do
      post "create_selected"
    end
  end

  post "/budgets_export", to: "budgets_export#create"

  resources :import_budgets, only: [] do
    collection do
      get :import
      get :import_preview
      post :import_preview
      post :submit_import
    end
  end
end
