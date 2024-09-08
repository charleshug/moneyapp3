module TrxesHelper
  include Pagy::Frontend
  def formatted_amount_for_form(amount_in_cents)
    amount_in_cents.to_f / 100
  end

  def amount_from_form(decimal_amount)
    (decimal_amount.to_f * 100).to_i
  end
end
