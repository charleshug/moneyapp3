json.extract! budget, :id, :name, :description, :currency, :user_id, :created_at, :updated_at
json.url budget_url(budget, format: :json)
