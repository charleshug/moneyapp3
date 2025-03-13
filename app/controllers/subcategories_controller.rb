class SubcategoriesController < ApplicationController
  before_action :set_subcategory, only: %i[ show edit update destroy ]

  # GET /subcategories or /subcategories.json
  def index
    @subcategories = Subcategory.all
  end

  # GET /subcategories/1 or /subcategories/1.json
  def show
  end

  # GET /subcategories/new
  def new
    @subcategory = Subcategory.new
  end

  # GET /subcategories/1/edit
  def edit
  end

  # POST /subcategories or /subcategories.json
  def create
    @subcategory = Subcategory.new(subcategory_params)

    respond_to do |format|
      if @subcategory.save
        format.html { redirect_to categories_path, notice: "Subcategory was successfully created." }
        format.json { render :show, status: :created, location: @subcategory }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subcategory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subcategories/1 or /subcategories/1.json
  def update
    respond_to do |format|
      if @subcategory.update(subcategory_params)
        # format.html { redirect_to subcategory_url(@subcategory), notice: "Subcategory was successfully updated." }
        format.html { redirect_to categories_path, notice: "Subcategory was successfully updated." }
        format.json { render :show, status: :ok, location: @subcategory }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subcategory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subcategories/1 or /subcategories/1.json
  def destroy
    @subcategory.destroy!

    respond_to do |format|
      format.html { redirect_to categories_path, notice: "Subcategory was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def sort
    subcategory = Subcategory.find(params[:id])

    if params[:direction] == "up" && subcategory.order > 1
      swap_with_previous(subcategory)
    elsif params[:direction] == "down" && subcategory.order < subcategory.category.subcategories.size
      swap_with_next(subcategory)
    else
      # Do nothing if already at the top or bottom
    end

    redirect_to categories_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subcategory
      @subcategory = Subcategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subcategory_params
      params.require(:subcategory).permit(:name, :hidden, :category_id)
    end

    def swap_with_previous(subcategory)
      previous_order = subcategory.order - 1
      previous_subcategory = subcategory.category.subcategories
        .where("subcategories.order = ?", previous_order)
        .first

      if previous_subcategory
        Subcategory.transaction do
          current_order = subcategory.order
          subcategory.update_column(:order, 0)
          previous_subcategory.update_column(:order, current_order)
          subcategory.update_column(:order, previous_order)
        end
      end
    end

    def swap_with_next(subcategory)
      next_order = subcategory.order + 1
      next_subcategory = subcategory.category.subcategories
        .where("subcategories.order = ?", next_order)
        .first

      if next_subcategory
        Subcategory.transaction do
          current_order = subcategory.order
          subcategory.update_column(:order, 0)
          next_subcategory.update_column(:order, current_order)
          subcategory.update_column(:order, next_order)
        end
      end
    end
end
