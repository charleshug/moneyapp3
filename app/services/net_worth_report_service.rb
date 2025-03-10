class NetWorthReportService
  def initialize(current_budget, params)
    @current_budget = current_budget
    @params = params
    @q = build_ransack_query
  end

  def call
    return {} if all_transactions.empty?

    set_date_range
    calculate_net_worth
  end

  def build_ransack_query
    # Only build query with account filter
    account_params = @params[:q]&.slice(:trx_account_id_in) || {}
    @current_budget.lines.includes(:trx).ransack(account_params)
  end

  private

  def all_transactions
    @all_transactions ||= @q.result.map(&:trx).uniq
  end

  def set_date_range
    if @params[:q] && @params[:q][:trx_date_gteq].present? && @params[:q][:trx_date_lteq].present?
      @start_date = Date.parse(@params[:q][:trx_date_gteq])
      @end_date = Date.parse(@params[:q][:trx_date_lteq])
    else
      @start_date = all_transactions.min_by(&:date).date.beginning_of_month
      @end_date = Date.current.end_of_month
    end
  end

  def calculate_net_worth
    # Calculate initial balance from all transactions before start_date
    initial_balance = all_transactions.select { |trx| trx.date < @start_date }.sum(&:amount)

    # Group transactions by month (only for display range)
    display_transactions = all_transactions.select { |trx| trx.date.between?(@start_date, @end_date) }
    transactions_by_month = display_transactions.group_by { |trx| trx.date.strftime("%Y-%m") }

    net_worth_hash = {}
    running_balance = initial_balance
    current_date = @start_date

    while current_date <= @end_date
      month_key = current_date.strftime("%Y-%m")
      month_transactions = transactions_by_month[month_key] || []
      amount_for_month = month_transactions.sum(&:amount)
      running_balance += amount_for_month

      net_worth_hash[current_date] = {
        amount: amount_for_month,
        running_balance: running_balance
      }

      current_date = current_date.next_month
    end

    net_worth_hash
  end
end
