# app/services/trx_csv_exporter.rb
class TrxCsvExporter
  def initialize(trxes)
    @trxes = trxes
  end

  def generate_csv
    attributes = %w[id date account_name vendor_name memo line_id category_name subcategory_name line_memo amount]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      @trxes.each do |trx|
        trx.lines.each do |line|
          csv << [
            trx.id,
            trx.date,
            trx.account&.name,
            trx.vendor&.name,
            trx.memo,
            line.id,
            line.ledger&.subcategory&.category&.name,
            line.ledger&.subcategory&.name,
            line.memo,
            line.amount.to_f / 100
          ]
        end
      end
    end
  end
end
