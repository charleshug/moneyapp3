class AccountsController < ApplicationController
  before_action :set_account, only: %i[ edit update destroy ]

  def index
    session[:page]="Accounts"
    @accounts = @current_budget.accounts.all.order(:id)

    @on_budget_accounts = @accounts.where(closed: false, on_budget: true)
    @on_budget_balance = @on_budget_accounts.sum(:balance)
    @off_budget_accounts = @accounts.where(closed: false, on_budget: false)
    @off_budget_balance = @off_budget_accounts.sum(:balance)
    @closed_accounts = @accounts.where(closed: true)
    @closed_balance = @closed_accounts.sum(:balance)
    @total_balance = @on_budget_balance + @off_budget_balance + @closed_balance
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
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    account = Account.find(params[:id])

    # Ensure the record belongs to the current budget
    if @account.budget != @current_budget
      redirect_to accounts_path, alert: "You are not authorized to edit this account."
      return
    end

    @account = AccountEditingService.new.edit_account(
      account,
      account_params
      )
    respond_to do |format|
      if @account.valid?
        format.html { redirect_to accounts_path, notice: "Account was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
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
    end

    rescue ActiveRecord::RecordNotDestroyed => e
      respond_to do |format|
        format.html { redirect_to edit_account_path(@account), alert: e.message }
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
