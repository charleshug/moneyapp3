class TrxImportService
  require 'csv'

  def self.parse(file)
    temp_table = CSV.read(file, headers: true)
    temp_array = temp_table.map(&:to_hash)

    # Check if all accounts exist
    temp_account_list = temp_table["Account"].uniq
    return false unless temp_account_list.all? { |a| Account.find_by(name: a) || "" }

    temp_array
  end

  def self.import(file)
    ActiveRecord::Base.transaction do
      temp_table = CSV.read(file, headers:true)
      temp_account_list = temp_table["Account"].uniq

      #Ensure all Accounts listed actually exist in our database
      return false unless temp_account_list.all? { |a| Account.find_by(name: a) || "" }

      #Placeholder category in case a listed Category doesn't exist in our database
      other = Category.find_or_create_by(name:"Other")
      uncategorized = other.subcategories.find_or_create_by(name:"Uncategorized")
      
      temp_array = temp_table.map { |row| row.to_hash }
      temp_array.each.with_index do |row,index|
        if row["Date"]
          date = Date.parse(row["Date"])
          account = Account.find_by(name: row["Account"])
          vendor = Vendor.find_or_create_by(name: row["Vendor"])
          category = Category.find_by(name: row["Category"]) || other
          subcategory = Subcategory.find_by(name: row["Subcategory"]) || uncategorized
          ledger = Ledger.find_or_create_by(date:date.end_of_month ,category:category)

          temp_trx_attr = {
            date: date,
            memo: row["Memo"],
            vendor: vendor,
            subcategory: subcategory,
            account: account,
            ledger: ledger,
            amount: convert_amount_to_cents(row["Amount"])
          }
          temp_trx = Trx.new(temp_trx_attr)
          temp_trx.save!
        elsif row["Account"]
          raise ("ERROR: Trx has Account but no date")
        end
      end

      temp_account_list.each do |account|
        Account.find_by_name(account).calculate_balance!
      end

    end

    #TODO: Ledger update logic is complex, this catchall is simpler for now
    LedgerService.update_all_ledgers
  end

  def convert_amount_to_cents(amount)
    (trx.amount.to_d * 100).to_i
  end
end