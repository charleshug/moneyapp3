module ApplicationHelper
  include Pagy::Frontend

  def full_title(page_title = "")
    base_title = "MoneyApp"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def custom_pagy_nav(pagy)
    html = +""  # Initialize a string buffer with an unfrozen string

    html << %(
      <nav class="pagy-nav pagination" aria-label="pager">
        <span class="page-count">Page #{pagy.page} of #{pagy.pages}</span>
    )

    if pagy.pages > 1  # Only show arrows if more than one page
      # Previous link
      html << if pagy.prev
        %(<span class="prev">#{link_to '<', pagy_url_for(pagy, pagy.prev), rel: 'prev', aria: { label: 'previous' }, class: 'px-3 py-2 rounded hover:bg-gray-200'}</span>)
      else
        %(<span class="prev disabled"><</span>)
      end

      # Next link
      html << if pagy.next
        %(<span class="next">#{link_to '>', pagy_url_for(pagy, pagy.next), rel: 'next', aria: { label: 'next' }, class: 'px-3 py-2 rounded hover:bg-gray-200'}</span>)
      else
        %(<span class="next disabled">></span>)
      end
    end

    html << %(</nav>)

    html.html_safe
  end

  def budget_year_range_for_select
    current_year = Date.current.year
    url_year = params.dig(:date, :year).to_i if params.dig(:date, :year).present?

    # Get the earliest and latest years from ledgers in the current budget
    ledger_years = @current_budget.ledgers.pluck(:date).map(&:year).uniq.sort

    if ledger_years.any?
      earliest_year = ledger_years.first
      latest_year = ledger_years.last
    else
      earliest_year = current_year
      latest_year = current_year
    end

    # If URL year is provided, adjust the range
    if url_year.present?
      if url_year < earliest_year
        earliest_year = url_year
      elsif url_year > latest_year
        latest_year = url_year
      end
    end

    # Generate the range of years
    (earliest_year..latest_year).to_a.reverse
  end
end
