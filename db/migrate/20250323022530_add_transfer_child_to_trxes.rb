class AddTransferChildToTrxes < ActiveRecord::Migration[7.0]
  def change
    add_column :trxes, :transfer_child, :boolean, default: false, null: false

    # Add an index for faster queries when filtering by transfer_child
    add_index :trxes, :transfer_child

    reversible do |dir|
      dir.up do
        # This migration needs to use Ruby code instead of SQL for the complex logic
        say_with_time "Marking transfer child transactions" do
          # Create a set to track processed transactions
          processed_trxes = Set.new

          # Step 1: Process multi-line transactions
          say "Processing multi-line transactions..."
          multi_line_trxes = execute("SELECT id FROM trxes WHERE id IN (SELECT trx_id FROM lines GROUP BY trx_id HAVING COUNT(*) > 1)").to_a.map { |row| row['id'] }

          multi_line_trxes.each do |trx_id|
            # Add this multi-line transaction to processed list
            processed_trxes.add(trx_id)

            # Get all lines with transfer_line_id for this transaction
            transfer_lines = execute("
              SELECT l.transfer_line_id
              FROM lines l
              WHERE l.trx_id = #{trx_id} AND l.transfer_line_id IS NOT NULL
            ").to_a

            transfer_lines.each do |row|
              transfer_line_id = row['transfer_line_id']

              # Get the transaction ID for this transfer line
              transfer_trx_id = execute("
                SELECT trx_id
                FROM lines
                WHERE id = #{transfer_line_id}
              ").to_a.first&.dig('trx_id')

              if transfer_trx_id
                # Mark as transfer child
                execute("UPDATE trxes SET transfer_child = true WHERE id = #{transfer_trx_id}")
                # Add to processed list
                processed_trxes.add(transfer_trx_id)
              end
            end
          end

          # Step 2: Process remaining transactions with transfer lines
          say "Processing remaining transactions with transfer lines..."
          remaining_trxes = execute("
            SELECT DISTINCT t.id
            FROM trxes t
            JOIN lines l ON l.trx_id = t.id
            WHERE l.transfer_line_id IS NOT NULL
          ").to_a.map { |row| row['id'] }

          remaining_trxes.each do |trx_id|
            # Skip if already processed
            next if processed_trxes.include?(trx_id)

            # Add to processed list
            processed_trxes.add(trx_id)

            # Get transfer line
            transfer_line = execute("
              SELECT l.transfer_line_id
              FROM lines l
              WHERE l.trx_id = #{trx_id} AND l.transfer_line_id IS NOT NULL
              LIMIT 1
            ").to_a.first

            if transfer_line
              transfer_line_id = transfer_line['transfer_line_id']

              # Get the transaction ID for this transfer line
              transfer_trx_id = execute("
                SELECT trx_id
                FROM lines
                WHERE id = #{transfer_line_id}
              ").to_a.first&.dig('trx_id')

              if transfer_trx_id
                # Mark as transfer child
                execute("UPDATE trxes SET transfer_child = true WHERE id = #{transfer_trx_id}")
                # Add to processed list
                processed_trxes.add(transfer_trx_id)
              end
            end
          end

          say "Processed #{processed_trxes.size} transactions, marked #{processed_trxes.size - multi_line_trxes.size} as transfer children"
        end
      end
    end
  end
end
