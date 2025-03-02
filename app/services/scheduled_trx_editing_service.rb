class ScheduledTrxEditingService
  def edit_trx(trx, trx_params)
    ActiveRecord::Base.transaction do
      convert_amount_to_cents(trx_params)

      trx.assign_attributes(trx_params)
      trx.set_amount
      trx.save
      if trx.invalid?
        # trx failed, do something
      end

      trx
    end
  end

  def convert_amount_to_cents(trx_params)
    return unless trx_params[:scheduled_lines_attributes].present?

    trx_params[:scheduled_lines_attributes].each do |_, line_params|  # Keep index key (_ ignored)
      if line_params[:amount].present?
        line_params[:amount] = (line_params[:amount].to_d * 100).to_i
      end
    end
  end
end
