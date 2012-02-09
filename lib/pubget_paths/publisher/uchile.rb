class Publisher::Uchile < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_title(article)
    url
  end

  def search_by_title(article)
    atitle = article.title
    qstring_url = join_url("browse?type=title&sort_by=1&order=ASC&rpp=20&starts_with=#{URI.escape atitle}")
    results_page = CachedWebPage.get_cached_doc(:url => qstring_url, :grep => 'uchile')
    results = results_page.search("table.miscTable > tr > td.evenRowOddCol > strong > a")

    max_diff = 10
    match = nil

    results.each do |result|
      title = result.render_to_plain_text
      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = result
      end
    end

    return nil unless match

    issue_url = join_url(match['href'])
    issue_page = CachedWebPage.get_cached_doc(:url => issue_url, :grep => 'uchile')
    pdf_link = issue_page.at("table.miscTable > tr > td > table > tr > td > a[text()='Ver/Abrir ']")

    return nil unless pdf_link

    join_url(pdf_link['href'])
  end

  def join_url(part)
    URI.parse("http://captura.uchile.cl/jspui/").merge(part).to_s
  end
end