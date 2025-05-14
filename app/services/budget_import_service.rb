class BudgetImportService
  class ImportError < StandardError; end

  def self.parse(file, budget)
    result = { ledgers: [], warnings: [] }

    begin
      csv_data = CSV.parse(file.read, headers: true)

      # Validate headers
      required_headers = [ "Date", "Subcategory", "Budget" ]
      missing_headers = required_headers - csv_data.headers
      if missing_headers.any?
        raise ImportError, "Missing required headers: #{missing_headers.join(', ')}"
      end

      # Validate subcategories
      subcategory_names = csv_data.map { |row| row["Subcategory"] }.uniq
      existing_subcategories = budget.subcategories.where(name: subcategory_names)
      missing_subcategories = subcategory_names - existing_subcategories.pluck(:name)

      if missing_subcategories.any?
        raise ImportError, "The following subcategories do not exist in your budget: #{missing_subcategories.join(', ')}"
      end

      subcategory_map = existing_subcategories.index_by(&:name)

      csv_data.each do |row|
        begin
          date = Date.parse(row["Date"]).strftime("%Y-%m-%d")
          subcategory = subcategory_map[row["Subcategory"]]
          budget_amount = parse_amount(row["Budget"])
          carry_forward = row["Carry Forward Negative Balance"].present? ?
                         row["Carry Forward Negative Balance"].downcase == "true" :
                         nil

          result[:ledgers] << {
            date: date,
            subcategory_id: subcategory.id,
            subcategory_name: subcategory.name,
            budget: budget_amount,
            carry_forward_negative_balance: carry_forward
          }
        rescue Date::Error
          result[:warnings] << "Invalid date format in row: #{row.to_h}"
        rescue ArgumentError
          result[:warnings] << "Invalid budget amount in row: #{row.to_h}"
        end
      end
    rescue CSV::MalformedCSVError
      raise ImportError, "Invalid CSV file format"
    end

    result
  end

  def self.parse_amount(amount_str)
    return nil unless amount_str.present?

    # Remove any currency symbols and whitespace
    cleaned = amount_str.gsub(/[$,\s]/, "")

    # Handle parentheses for negative numbers
    if cleaned.match?(/^\((.*)\)$/)
      cleaned = "-#{cleaned.gsub(/[()]/, '')}"
    end

    (BigDecimal(cleaned.to_s) * BigDecimal("100")).to_i
  end
end
