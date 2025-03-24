class TrxImportService
  require "csv"
  class ImportError < StandardError; end

  REQUIRED_HEADERS = [ "Date", "Account", "Vendor", "Subcategory", "Amount" ].freeze
  OPTIONAL_HEADERS = [ "Memo", "Cleared", "Group" ].freeze
  DATE_FORMATS = [ "%m/%d/%Y", "%Y-%m-%d", "%d/%m/%Y" ].freeze

  def self.parse(file, budget)
    raise ImportError, "No file provided" unless file
    raise ImportError, "Invalid file type" unless valid_file_type?(file)

    # Read file content and handle encoding issues
    csv_text = read_with_encoding(file)

    begin
      csv = CSV.parse(csv_text, headers: true)
    rescue CSV::MalformedCSVError => e
      raise ImportError, "CSV parsing error: #{e.message}"
    end

    Rails.logger.debug "CSV Headers: #{csv.headers.inspect}"
    validate_headers!(csv.headers)

    # Group transactions based on presence of Group field
    has_group_field = csv.headers.include?("Group")
    grouped_rows = if has_group_field
      csv.group_by { |row| [ row["Date"], row["Vendor"], row["Group"] ] }
    else
      # Each row becomes its own group unless it's a split transaction
      csv.group_by { |row| [ row["Date"], row["Vendor"], row.object_id ] }
    end

    Rails.logger.debug "Grouped Rows: #{grouped_rows.inspect}"
    Rails.logger.debug "Using Group field: #{has_group_field}"

    parsed_trxes = []
    warnings = []

    grouped_rows.each do |(date, vendor, group), rows|
      begin
        next if date.blank? || vendor.blank?

        # Parse the first row for common transaction data
        first_row = rows.first
        parsed_date = parse_date(first_row["Date"])
        raise ImportError, "Invalid date format: #{date}" unless parsed_date

        account_id = find_account_id(first_row["Account"], budget)
        raise ImportError, "Account not found: #{first_row['Account']}" unless account_id

        vendor_id = find_or_create_vendor_id(vendor, budget)

        # Build the transaction hash
        trx = {
          "date" => parsed_date.strftime("%Y-%m-%d"),
          "memo" => first_row["Memo"],
          "account_id" => account_id,
          "vendor_id" => vendor_id,
          "lines_attributes" => {}
        }

        total_amount = 0
        # Add lines from all rows in the group
        rows.each_with_index do |row, index|
          amount = parse_amount(row["Amount"])
          next unless amount

          subcategory_id = find_subcategory_id(row["Subcategory"], budget)
          unless subcategory_id
            warnings << "Subcategory not found: #{row['Subcategory']}"
            next
          end

          # Convert amount to cents and store as integer
          amount_in_cents = (BigDecimal(amount.to_s) * BigDecimal("100")).to_i

          trx["lines_attributes"][index.to_s] = {
            "subcategory_id" => subcategory_id,
            "amount" => amount_in_cents
          }
          total_amount += amount_in_cents
        end

        if trx["lines_attributes"].any?
          parsed_trxes << trx
          Rails.logger.debug "Added transaction: #{trx.inspect}"
        end
      rescue StandardError => e
        warnings << "Row error (#{vendor} - #{date}): #{e.message}"
        Rails.logger.error "Row error: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end

    Rails.logger.debug "Final parsed transactions: #{parsed_trxes.inspect}"
    Rails.logger.debug "Warnings: #{warnings.inspect}"

    { trxes: parsed_trxes, warnings: warnings }
  end

  def self.import(file)
    ActiveRecord::Base.transaction do
      temp_table = CSV.read(file, headers: true)
      temp_account_list = temp_table["Account"].uniq

      # Ensure all Accounts listed actually exist in our database
      return false unless temp_account_list.all? { |a| Account.find_by(name: a) || "" }

      # Placeholder category in case a listed Category doesn't exist in our database
      other = @current_budget.categories.find_or_create_by(name: "Other")
      uncategorized = other.subcategories.find_or_create_by(name: "Uncategorized")


      ledgers_to_update = Set.new
      accounts_to_update = Set.new

      temp_array = temp_table.map { |row| row.to_hash }
      temp_array.each.with_index do |row, index|
        if row["Date"]
          date = Date.parse(row["Date"])
          account = @current_budget.accounts.find_by(name: row["Account"])
          vendor = @current_budget.vendors.find_or_create_by(name: row["Vendor"])
          subcategory = @current_budget.subcategories.find_by(name: row["Subcategory"]) || uncategorized

          temp_trx_attr = {
            date: date,
            memo: row["Memo"],
            vendor: vendor,
            account: account,
            lines: [
              {
                subcategory: subcategory,
                amount: convert_amount_to_cents(row["Amount"])
              }
            ]
          }

          temp_trx = Trx.new(temp_trx_attr)
          set_ledger(temp_trx)
          temp_trx.save!

          temp_trx.lines.each { |line| ledgers_to_update << line.ledger }
          accounts_to_update << temp_trx.account

        elsif row["Account"]
          raise ("ERROR: Trx has Account but no date")
        end
      end

      # update Ledgers and Accounts all at once at the end
      ledgers_to_update.each do |ledger|
        LedgerService.recalculate_forward_ledgers(ledger)
      end
      accounts_to_update.each do |account|
        account.calculate_balance!
      end
    end
  end

  def convert_amount_to_cents(amount)
    (trx.amount.to_d * 100).to_i
  end

  private

  # New method to handle different encodings
  def self.read_with_encoding(file)
    # Try to read with UTF-8 first
    content = file.read

    # Check if content is valid UTF-8
    unless content.force_encoding("UTF-8").valid_encoding?
      # If not valid UTF-8, try other common encodings
      [ "Windows-1252", "ISO-8859-1", "CP1252" ].each do |encoding|
        begin
          Rails.logger.debug "Trying #{encoding} encoding"
          converted_content = content.force_encoding(encoding).encode("UTF-8")
          if converted_content.valid_encoding?
            Rails.logger.debug "Successfully converted from #{encoding} to UTF-8"
            return converted_content
          end
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
          Rails.logger.debug "Conversion from #{encoding} failed: #{e.message}"
          next
        end
      end

      # If we get here, none of our encoding attempts worked
      raise ImportError, "Unable to determine file encoding. Please save your CSV as UTF-8."
    end

    # Return the content if it's already valid UTF-8
    content
  end

  def self.valid_file_type?(file)
    File.extname(file.original_filename).downcase == ".csv"
  end

  def self.validate_headers!(headers)
    missing_headers = REQUIRED_HEADERS - headers.map(&:to_s)
    raise ImportError, "Missing required headers: #{missing_headers.join(', ')}" if missing_headers.any?
  end

  def self.parse_date(date_str)
    return nil unless date_str.present?

    DATE_FORMATS.each do |format|
      begin
        return Date.strptime(date_str, format)
      rescue ArgumentError
        next
      end
    end

    begin
      Date.parse(date_str)
    rescue ArgumentError
      nil
    end
  end

  def self.parse_amount(amount_str)
    return nil unless amount_str.present?

    # Remove any currency symbols and whitespace
    cleaned = amount_str.gsub(/[$,\s]/, "")

    # Handle parentheses for negative numbers
    if cleaned.match?(/^\((.*)\)$/)
      cleaned = "-#{cleaned.gsub(/[()]/, '')}"
    end

    # Convert to BigDecimal
    BigDecimal(cleaned)
  end

  def self.find_account_id(account_name, budget)
    return nil unless account_name.present?
    budget.accounts.find_by("LOWER(name) = ?", account_name.downcase)&.id
  end

  def self.find_or_create_vendor_id(memo, budget)
    return nil unless memo.present?
    vendor = budget.vendors.find_by("LOWER(name) = ?", memo.downcase)
    vendor ||= budget.vendors.create!(name: memo)
    vendor.id
  end

  def self.find_subcategory_id(category_name, budget)
    return nil unless category_name.present?

    # Try to match category - subcategory format
    if category_name.include?(" - ")
      category_name, subcategory_name = category_name.split(" - ").map(&:strip)
      category = budget.categories
        .where("LOWER(categories.name) = ?", category_name.downcase)
        .first

      return category&.subcategories
        .where("LOWER(subcategories.name) = ?", subcategory_name.downcase)
        &.first&.id
    end

    # Try direct subcategory match
    budget.subcategories
      .where("LOWER(subcategories.name) = ?", category_name.downcase)
      .first&.id
  end

  def self.validate_transaction!(trx, total_amount)
    raise ImportError, "No lines found for transaction" if trx["lines_attributes"].empty?
    raise ImportError, "Transaction total amount does not balance" unless total_amount.abs < 0.001
  end
end
