class VendorsController < ApplicationController
  before_action :set_vendor, only: %i[ edit update destroy ]

  def index
    vendors = @current_budget.vendors
    @vendors = vendors.not_transfer.order("LOWER(name)")
  end

  def new
    @vendor = Vendor.new
    respond_to do |format|
      format.html { render :new }
      format.turbo_stream { render :new_form }
    end
  end

  def create
    vendor = @current_budget.vendors.build(vendor_params)
    @vendor = VendorService.new.create_vendor(vendor)
    respond_to do |format|
      if @vendor.valid?
        format.html { redirect_to vendors_path, notice: "Vendor was successfully created." }
        format.turbo_stream { render :create }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :create_error }
      end
    end
  end

  def edit
    # Ensure the record belongs to the current budget
    if @vendor.budget != @current_budget
      redirect_to vendors_path, alert: "You are not authorized to edit this record."
      return
    end

    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream { render :edit_form }
    end
  end

  def update
    # Ensure the record belongs to the current budget
    if @vendor.budget != @current_budget
      redirect_to vendors_path, alert: "You are not authorized to edit this record."
      return
    end

    @vendor = VendorService.new.update_vendor(@vendor, vendor_params)
    respond_to do |format|
      if @vendor.valid?
        format.html { redirect_to vendors_path, notice: "Vendor was successfully updated." }
        format.turbo_stream { render :update }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :update_error }
      end
    end
  end

  def destroy
    # Ensure the record belongs to the current budget
    if @vendor.budget != @current_budget
      redirect_to vendors_path, alert: "You are not authorized to delete this record."
      return
    end

    @vendor.destroy
    respond_to do |format|
      format.html { redirect_to vendors_path, notice: "Vendor was successfully deleted." }
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace("modal", "<turbo-frame id=\"modal\"></turbo-frame>"),
          turbo_stream.replace("vendors_list", partial: "vendors/list", locals: { vendors: @current_budget.vendors.not_transfer.order("LOWER(name)") })
        ]
      }
    end
  end

  def search
    query = params[:q]&.strip
    budget_id = params[:budget_id]

    if query.present?
      vendors = @current_budget.vendors
                              .where("LOWER(name) ILIKE ?", "%#{query.downcase}%")
                              .order("LOWER(name)")
                              .limit(20)
    else
      vendors = @current_budget.vendors
                              .order("LOWER(name)")
                              .limit(50)
    end

    vendor_data = vendors.map do |vendor|
      {
        id: vendor.id,
        name: vendor.name,
        is_transfer: vendor.account.present?
      }
    end

    respond_to do |format|
      format.json { render json: { vendors: vendor_data } }
    end
  end

  private
  def set_vendor
    @vendor = Vendor.find(params[:id])
  end

  def vendor_params
    params.require(:vendor).permit(:name)
  end
end
