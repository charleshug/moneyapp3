class SpendingByCategoryReportService
  def self.get_hash_line_by_category_1(lines_input)
    line_amounts = lines_input.joins(ledger: { subcategory: :category })
                            .group("subcategories.id", "categories.id")
                            .sum(:amount)

    categorized_amounts = Hash.new { |hash, key| hash[key] = { amount: 0, subcategories: {}, total: 0 } }

    # Iterate over the aggregated results
    line_amounts.each do |(subcategory_id, category_id), amount|
      if category_id.nil?
        categorized_amounts[subcategory_id][:amount] += amount
        categorized_amounts[subcategory_id][:total] += amount
      else
        categorized_amounts[category_id][:subcategories][subcategory_id] = amount
        categorized_amounts[category_id][:total] += amount
      end
    end

    # Sort by parent category ID and subcategories by ID
    categorized_amounts.sort.to_h
  end

  def self.get_hash_line_by_category
    # TODO - update with @current_budget
    SpendingByCategoryReportService.get_hash_line_by_category_1(Line.all)
  end
end
