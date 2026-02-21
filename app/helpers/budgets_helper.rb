module BudgetsHelper
  # Responsive visibility for multi-month columns: 1 col default, 2 at md, 3 at lg, 4 at xl
  def budget_month_col_visible(index)
    case index
    when 0 then ""
    when 1 then "hidden md:table-cell"
    when 2 then "hidden lg:table-cell"
    else "hidden xl:table-cell"
    end
  end
end
