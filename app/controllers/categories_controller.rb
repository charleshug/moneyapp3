class CategoriesController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    # debugger
    @categories = @current_budget.categories.expense.includes(:subcategories)
  end

  def new
    @category = Category.new
    @categories = @current_budget.categories
  end

  def create
    @category = @current_budget.categories.build(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category was successfully created."
    else
      render :new
    end
  end

  def edit
    @category = Category.find(params[:id])

    # Ensure the record belongs to the current budget
    if @category.budget != @current_budget
      redirect_to categories_path, alert: "You are not authorized to edit this category."
      return
    end

    @categories = @current_budget.categories
  end

  def update
    # Ensure the record belongs to the current budget
    if @category.budget != @current_budget
      redirect_to categories_path, alert: "You are not authorized to update this category."
      return
    end
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Ensure the category belongs to the current budget
    if @category.budget != @current_budget
      redirect_to categories_path, alert: "You are not authorized to delete this category."
      return
    end

    @category.destroy!
    respond_to do |format|
      format.html { redirect_to categories_url, notice: "Category was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :hidden)
  end
end
