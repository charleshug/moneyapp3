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
end
