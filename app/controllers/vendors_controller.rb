class VendorsController < ApplicationController
  before_action :set_vendor, only: %i[ edit update ]

  def index
    vendors = @current_budget.vendors
    @vendors = vendors.not_transfer.order("LOWER(name)")
  end

  def new
    @vendor = Vendor.new
  end

  def create
    vendor = @current_budget.vendors.build(vendor_params)
    @vendor = VendorService.new.create_vendor(vendor)
    respond_to do |format|
      if @vendor.valid?
        format.html { redirect_to vendors_path, notice: "Vendor was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    # Ensure the record belongs to the current budget
    if @vendor.budget != @current_budget
      redirect_to vendors_path, alert: "You are not authorized to edit this record."
      nil
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
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
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
