class Publisher::Asm < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]
    search_url = get_search_url(article)
    page, redirect_url = CachedWebPage.get_cached_doc(:url => search_url, :details=>true, :expire_in => 1.week) if search_url
    results = page.search('table#search-results-table > tr > td > font')

    match = nil
    title = article.title
    max_diff = 10

    results.each do |result|
      title_matches = result.search("table > tr > td[@valign=TOP] > font > strong")

      title_matches.each do |title_match|
        diff = String.diff_string(title, title_match.text)

        if diff < max_diff
          max_diff = diff
          match = result
          break
        end
      end
    end

    if match
      a = match.at("td[@valign=TOP] > table a[text()='PDF']")
      url = a['href'].gsub(/\?.*/, '') if a
      url += ".pdf" if url.scan(/^.*\.pdf/i).empty?
    end

    url
  end

  def get_search_url(article)
    doi = article.doi || article.get_doi
    title = article.title
    base_url = "#{article.journal.base_url || 'http://aac.asm.org'}/cgi/search?sendit=Search"

    if doi and doi.scan(/^.*\/AAC\..*/).any?
      "#{base_url}&DOI=#{doi.match(/^.*\/AAC\.(.*)/)[1]}&sortspec=relevance&sortspecbrief=relevance"
    elsif title
      "#{base_url}&title=#{title}&andorexacttitle=or&sortspec=relevance&sortspecbrief=relevance"
    end
  end
end