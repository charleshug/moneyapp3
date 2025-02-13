class TrxImportService
  require "csv"

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
          # category = @current_budget.categories.find_by(name: row["Category"]) || other
          subcategory = @current_budget.subcategories.find_by(name: row["Subcategory"]) || uncategorized
          # ledger = @current_budget.ledger.find_or_create_by(date: date.end_of_month, subcategory: subcategory)

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
          debugger
          temp_trx.save!

          temp_trx.lines.each { |line| ledgers_to_update << line.ledger }
          accounts_to_update << temp_trx.account

        elsif row["Account"]
          raise ("ERROR: Trx has Account but no date")
        end
      end

      # update Ledgers and Accounts all at once at the end
      ledgers_to_update.each do |ledger|
        LedgerService.new.recalculate_forward_ledgers(ledger)
      end
      accounts_to_update.each do |account|
        account.calculate_balance!
      end
    end
  end

  def convert_amount_to_cents(amount)
    (trx.amount.to_d * 100).to_i
  end
end
