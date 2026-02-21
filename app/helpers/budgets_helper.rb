module BudgetsHelper
  # Container-query visibility: hide rightmost month when container isn't wide enough (~400px per month group).
  # Based on table wrapper width, not viewport. 1 month always; 2nd at 800px; 3rd at 1200px; 4th at 1600px.
  def budget_month_col_visible(index)
    case index
    when 0 then ""
    when 1 then "hidden @min-[800px]:table-cell"
    when 2 then "hidden @min-[1200px]:table-cell"
    else "hidden @min-[1600px]:table-cell"
    end
  end

  # Min-width so month column group stays ~400px and content below doesn't shrink further
  def budget_month_cell_min
    "min-w-[134px]"
  end
end
