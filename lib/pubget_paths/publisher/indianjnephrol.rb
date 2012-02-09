class Publisher::Indianjnephrol < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_title(article)
    #debugger

    url
  end

  def search_by_title(article)
    articles_url = issue_url(article)
    return nil unless articles_url

    articles_doc = CachedWebPage.get_cached_doc(:url => articles_url, :grep => 'indianjnephrol', :expired_in => Time.now.year != article.year.to_i ? nil : 1.weeks)
    results = articles_doc.search("td.articleTitle")
    atitle = raze(article.title)

    max_diff = 10
    match = nil

    results.each do |result|
      title = raze(result.render_to_plain_text)
      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = result.parent.next_sibling.next_sibling
      end
    end

    return nil unless match

    link = match.at("a[text()='[HTML Full text]']")
    return nil unless link

    join_url(link['href'])
  end

  def issue_url(article)
    year = article.year
    volume = article.volume
    issue = article.issue
    issn = article.pissn
    return nil if not year or not volume or not issue or not issn

    join_url("/showBackIssue.asp?issn=#{issn};year=#{year};volume=#{volume};issue=#{issue}")
  end

  def join_url(part)
    URI.parse("http://www.indianjnephrol.org/").merge(part).to_s
  end
end