class LedgerService
  def recalculate_forward_ledgers(ledger)
    ledgers = ordered_ledgers(ledger)
    ledgers.each(&:save!)
  end

  def ordered_ledgers(start_ledger)
    ledgers = [ start_ledger ]
    current_ledger = start_ledger

    while current_ledger.next
      current_ledger = current_ledger.next
      ledgers << current_ledger
    end

    ledgers
  end

  def update_prev_and_next(ledger)
    prev_ledger = ledger.find_prev_ledgers.first
    next_ledger = ledger.find_next_ledgers.first

    if prev_ledger
      ledger.prev = prev_ledger
      prev_ledger.update(next: ledger)
    end

    if next_ledger
      ledger.next = next_ledger
      next_ledger.update(prev: ledger)
    end

    ledger.save!
  end

  def self.create_necessary_ledgers
    # TODO - use current budget
    # 1. Convert Trx Dates to the Last Day of the Month
    trx_with_last_day_of_month = Trx.all.map do |trx|
      [ trx.subcategory_id, trx.date.end_of_month ]
    end

    # 2. Group and Select Unique Category/Date Pairs
    unique_category_date_pairs = trx_with_last_day_of_month.uniq

    # Output the unique pairs
    unique_category_date_pairs.each do |subcategory_id, date|
      puts "Ledger: date " + date.strftime("%Y-%b") + ", Category: " + Category.find(category_id).name
      ledger = Ledger.find_or_initialize_by(date: date, subcategory_id: subcategory_id)
      ledger.save
    end

    # TODO - use current_budget
    Ledger.all.each do |l|
      LedgerService.new.update_prev_and_next(l)
    end
  end

  def zero_all_budgeted_amounts(date)
    # TODO - use current budget
    ledgers = Ledger.where(date: date).where.not(budget: 0)
    ledgers.each do |ledger|
      ledger.update(budget: 0)
      recalculate_forward_ledgers(ledger)
    end
  end

  def budget_values_used_last_month(date)
    prev_month_date = date.prev_month.end_of_month
    prev_month_ledgers = Ledger.where(date: prev_month_date)
    prev_month_ledgers.each do |prev_ledger|
      if prev_ledger.budget != 0
        current_ledger = Ledger.find_or_initialize_by(subcategory_id: prev_ledger.subcategory_id, date: date)
        if current_ledger.budget == 0
          current_ledger.budget = prev_ledger.budget
          current_ledger.save
          recalculate_forward_ledgers(current_ledger)
        end
      end
    end
  end

  def last_month_outflows(date)
    prev_month_date = date.prev_month.end_of_month
    prev_month_ledgers = Ledger.where(date: prev_month_date)

    prev_month_ledgers.each do |prev_ledger|
      current_ledger = Ledger.find_or_initialize_by(subcategory_id: prev_ledger.subcategory_id, date: date)
      current_ledger.budget = -prev_ledger.actual
      current_ledger.save
      recalculate_forward_ledgers(current_ledger)
    end
  end

  def balance_to_zero(date)
    Ledger.where(date: date, budget: 0).each do |ledger|
      balance_to_zero = -ledger.balance
      ledger.update(budget: balance_to_zero)
      recalculate_forward_ledgers(ledger)
    end
  end

  def create_ledger(ledger_params)
    ledger = Ledger.new(ledger_params)
    ledger.budget = (BigDecimal(ledger_params[:budget])*100).to_s
    ledger.save
    if ledger.invalid?
      return ledger
    end

    update_prev_and_next(ledger)
    update_next_ledgers(ledger)

    ledger
  end

  def update_ledger(ledger, ledger_update_params)
    ledger_update_params[:budget]=(BigDecimal(ledger_update_params[:budget])*100).to_s
    ledger.update(ledger_update_params)
    if ledger.invalid?
      return ledger
    end

    update_prev_and_next(ledger)
    update_next_ledgers(ledger)
    ledger
  end

  def update_ledger_from_trx(trx)
    ledger = trx.ledger
    ledger.save
    if ledger.invalid?
      return ledger
    end
    update_next_ledgers(ledger)
    ledger
  end

  def update_ledger_from_line(line)
    ledger = line.ledger
    ledger.save
    if ledger.invalid?
      return ledger
    end
    update_next_ledgers(ledger)
    ledger
  end

  def update_next_ledgers(ledger)
    if next_ledger = ledger.find_next_ledgers.first
      next_ledger.save
      next_ledger.find_next_ledgers.each do |l|
        l.save
      end
    end
  end

  def self.update_all_ledgers
    # TODO - use current_budget
    ledger_heads = Ledger.where(prev: nil)
    ledger_heads.each do |head|
      head.save
      ledgers = head.find_next_ledgers
      ledgers.includes(:subcategory, :prev).each do |l|
        l.save
      end
    end
  end
end
