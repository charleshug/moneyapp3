class BillSplitterController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_budget
  skip_before_action :load_accounts_for_sidebar
  layout false

  def index
    # Serve the bill splitter as a standalone page
  end
end
