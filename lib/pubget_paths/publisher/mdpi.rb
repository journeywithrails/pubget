class Publisher::MDPI < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = guess_url(article)
    url = search_by_title(article) unless url

    url
  end

  def guess_url(article)
    return nil unless afirst_page = article.first_page
    page, page_url = issues_page(article)
    link = page.at("a[@href='#{"#{URI.parse(page_url).path}/#{afirst_page}/"}']")
    link ? join_url(link['href'] + "/pdf") : nil
  end

  def search_by_title(article)
    #atitle = article.title
    #page, page_url = issues_page(article)
    #page.search
  end

  def issues_page(article)
    aissn = article.issn.is_a?(Array) ? article.issn.first : article.issn
    avolume = article.volume
    aissue = article.issue
    return nil if !aissn.present? or !avolume.present? or !aissue.present?

    issues_path = "#{aissn}/#{avolume}/#{aissue}"
    issues_url = join_url(issues_path)
    page = CachedWebPage.get_cached_doc(:url => issues_url, :grep => 'mdpi')
    return page, issues_url
  end

  def join_url(part)
    URI.parse("http://www.mdpi.com/").merge(part).to_s
  end
end