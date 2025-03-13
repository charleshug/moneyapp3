class CategoriesController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    @categories = @current_budget.categories
      .includes(:subcategories)
      .order(:order)

    # Get min/max orders in a single query for categories
    @category_orders = @current_budget.categories
      .pluck("MIN(categories.order), MAX(categories.order)")
      .first

    # Get min/max orders for subcategories in a single query
    @subcategory_orders = Subcategory
      .joins(:category)
      .where(categories: { budget_id: @current_budget.id })
      .group(:category_id)
      .pluck("category_id, MIN(subcategories.order), MAX(subcategories.order)")
      .each_with_object({}) do |(category_id, min_order, max_order), hash|
        hash[category_id] = OpenStruct.new(min_order: min_order, max_order: max_order)
      end

    Category.initialize_orders(@current_budget.id) if @categories.any? { |c| c.order.nil? }
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

  def sort
    category = @current_budget.categories.find(params[:id])

    if params[:direction] == "up"
      swap_with_previous(category)
    elsif params[:direction] == "down"
      swap_with_next(category)
    else
      Category.sort_by_order(params[:category])
    end

    redirect_to categories_path
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :hidden)
  end

  def swap_with_previous(category)
    previous_category = @current_budget.categories
      .where("categories.order < ?", category.order)
      .order(order: :desc)
      .first

    if previous_category
      Category.transaction do
        temp_order = -1
        current_order = category.order
        prev_order = previous_category.order

        category.update_column(:order, temp_order)
        previous_category.update_column(:order, current_order)
        category.update_column(:order, prev_order)
      end
    end
  end

  def swap_with_next(category)
    next_category = @current_budget.categories
      .where("categories.order > ?", category.order)
      .order(:order)
      .first

    if next_category
      Category.transaction do
        temp_order = -1
        current_order = category.order
        next_order = next_category.order

        category.update_column(:order, temp_order)
        next_category.update_column(:order, current_order)
        category.update_column(:order, next_order)
      end
    end
  end
end
