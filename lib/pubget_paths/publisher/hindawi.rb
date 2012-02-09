class Publisher::Hindawi < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_title(article)

    url
  end

  def search_by_title(article)
    issues_url = journal_issues_url(article)
    return nil unless issues_url

    issues_doc = CachedWebPage.get_cached_doc(:url => issues_url, :grep => 'hindawi')
    issues = issues_doc.search("div.middle_content > ul > li > a")
    ititle = raze(article.title)

    issues.each do |issue|
      title = raze(issue.render_to_plain_text)
      return "http://downloads.hindawi.com#{issue['href'].gsub(/\/$/, '.pdf')}" if ititle == title
    end
  end

  def journal_issues_url(article)
    jtitle = raze(article.journal.title)
    year = article.year || article.volume
    return nil if not jtitle or not year

    journals_doc = CachedWebPage.get_cached_doc(:url => journals_url, :grep => 'hindawi')
    journals_links = journals_doc.search("div#browse_area > ul.li_special > li > a")

    journals_links.each do |jlink|
      title = raze(jlink.render_to_plain_text)
      return join_url("#{jlink['href']}/#{year}/") if jtitle == title
    end

    nil
  end

  def journals_url
    join_url('journals/')
  end

  def join_url(part)
    URI.parse("http://www.hindawi.com/").merge(part).to_s
  end
end