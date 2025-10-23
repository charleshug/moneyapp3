class AccountsController < ApplicationController
  before_action :set_account, only: %i[ edit update destroy ]

  def index
    session[:page] = "Accounts"

    # Group accounts by type
    @account_groups = {
      "Budget Accounts" => {
        accounts: @current_budget.accounts.where(closed: false, on_budget: true).order(:name),
        id: "budget_accounts"
      },
      "Off-Budget Accounts" => {
        accounts: @current_budget.accounts.where(closed: false, on_budget: false).order(:name),
        id: "off_budget_accounts"
      },
      "Closed Accounts" => {
        accounts: @current_budget.accounts.where(closed: true).order(:name),
        id: "closed_accounts"
      }
    }

    # Calculate balances
    @balances = {}
    @balances[:total] = 0

    @account_groups.each do |name, group|
      balance = group[:accounts].sum(:balance)
      @balances[name] = balance
      @balances[:total] += balance
    end
  end

  def show
    @account = Account.find(params[:id])

    # Ensure the account belongs to the current budget
    if @account.budget != @current_budget
      redirect_to accounts_path, alert: "The account does not belong to this budget."
      return
    end
    @trxes = @account.trxes.includes(:vendor, :category, :subcategory)
  end

  def new
    @account = Account.new
  end

  def edit
    # Ensure the record belongs to the current budget
    if @account.budget != @current_budget
      redirect_to accounts_path, alert: "You are not authorized to edit this account."
      nil
    end
  end

  def create
    account = @current_budget.accounts.build
    AccountCreator.new(account, account_params)
    respond_to do |format|
      if account.valid?
        format.html { redirect_to accounts_path, notice: "Account was successfully created." }
        format.turbo_stream { render :create }
      else
        @account = account
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    # before_action :set_account is called

    # Ensure the record belongs to the current budget
    if @account.budget != @current_budget
      redirect_to accounts_path, alert: "You are not authorized to edit this account."
      return
    end

    @account.update(account_params)
    respond_to do |format|
      if @account.valid?
        format.html { redirect_to accounts_path, notice: "Account was successfully updated." }
        format.turbo_stream { render :update }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # Ensure the record belongs to the current budget
    if @account.budget != @current_budget
      redirect_to accounts_path, alert: "You are not authorized to delete this account."
      return
    end

    @account.destroy!
    respond_to do |format|
      format.html { redirect_to accounts_path, notice: "Account was successfully destroyed." }
      format.turbo_stream { redirect_to accounts_path, notice: "Account was successfully destroyed." }
    end

  rescue ActiveRecord::RecordNotDestroyed => e
      respond_to do |format|
        format.html { redirect_to edit_account_path(@account), alert: e.message }
        format.turbo_stream { redirect_to edit_account_path(@account), alert: e.message }
      end
  end

  private
    def set_account
      @account = Account.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def account_params
      params.fetch(:account, {}).permit(
        :id, :name, :starting_date, :starting_balance, :closed, :on_budget)
    end
end
