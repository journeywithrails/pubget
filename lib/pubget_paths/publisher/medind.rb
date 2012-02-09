class Publisher::Medind < Publisher::Base
  def pdf_url(params={})
    article = params[:article]
    url = search_by_title(article)

    url
  end

  def search_by_title(article)
    articles_url = issue_url(article)
    return nil unless articles_url

    articles_doc = CachedWebPage.get_cached_doc(:url => articles_url, :grep => "medind")
    results = articles_doc.search("table[@align='center'] > tr > td > font > a.left")
    atitle = raze(article.title)

    max_diff = 10
    match = nil

    results.each do |result|
      title = raze(result.render_to_plain_text)

      if atitle == title
        match = result['href']
        break
      end
    end

    results.each do |result|
      title = raze(result.render_to_plain_text)
      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = result['href']
      end
    end unless match

    return articles_url.gsub(/\/[^\/]+$/, "/#{match}") if match
    nil
  end

  def issue_url(article)
    journal_url = journal_issues_url(article)
    return nil unless journal_url

    year = article.year
    volume = article.volume
    issue = article.issue
    year = (1933 + volume.to_i).to_s if not year.present? and volume.present?
    volume = (year.to_i - 1933).to_s if not volume.present? and year.present?
    return nil if not year.present? or not volume.present? or not issue.present?

    journal_doc = CachedWebPage.get_cached_doc(:url => journal_url, :grep => "medind")
    issue_link = journal_doc.at("a[text()='#{year}, Volume #{volume}, Issue #{issue}']")

    join_url(issue_link['href']) if issue_link
  end

  def journal_issues_url(article)
    jtitle = raze(article.journal.title)
    return nil unless jtitle

    journals_doc = CachedWebPage.get_cached_doc(:url => join_url, :grep => "medind")
    journals = journals_doc.search("table > tr > td > ul > li > a")

    journals.each do |journal|
      title = raze(journal.text)
      return join_url(journal['href'].gsub(/m\.shtml/, 'ai.shtml')) if jtitle == title
    end

    max_diff = 10
    match = nil

    journals.each do |journal|
      title = raze(journal.text)
      diff = String.diff_string(jtitle, title)

      if diff < max_diff
        max_diff = diff
        match = journal
      end
    end

    join_url(match['href'].gsub(/m\.shtml/, 'ai.shtml')) if match
  end

  def join_url(part = nil)
    return "http://medind.nic.in/" unless part
    URI.parse("http://medind.nic.in/").merge(part).to_s
  end
end
