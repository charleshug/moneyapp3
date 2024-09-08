class VendorService

  def create_vendor(vendor)
    vendor.save
    if vendor.invalid?
      return vendor
    end

    vendor
  end

  def update_vendor(vendor, vendor_params)
    vendor.update(vendor_params)
    if vendor.valid?
      #do something
    end
    
    vendor
  end

end