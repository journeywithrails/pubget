class Publisher::Soils < Publisher::Base
  def pdf_url(params={})
    article = params[:article]
    url = search_by_title(article)

    url
  end

  def search_by_title(article)
    articles_url = issue_url(article)
    return nil unless articles_url

    articles_doc = CachedWebPage.get_cached_doc(:url => articles_url, :grep => "soils")
    results = articles_doc.search("form ul > li > ul > li")
    atitle = raze(article.title)

    max_diff = 10
    match = nil

    results.each do |result|
      title_elem = result.at("strong")
      title = raze(title_elem.render_to_plain_text)
      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = result.at("a[text()='[ PDF ]']")
      end
    end

    return join_url(match['href']) if match
    nil
  end

  def issue_url(article)
    journal_url = journal_issues_url(article)
    return nil unless journal_url

    year = article.year
    year = (1971 + article.volume.to_i).to_s if not year.present? and article.volume.present?
    alast_page = article.last_page.to_i
    return nil if not year.present? or not alast_page

    journal_doc = CachedWebPage.get_cached_doc(:url => journal_url, :grep => "soils")
    issues_links = journal_doc.search("div#yearDetails#{year} > a")

    issues_links.each do |link|
      last_page = link.children.last.render_to_plain_text.gsub(/^.*-/, '')
      return join_url(link['href']) if alast_page <= last_page.to_i
    end
  end

  def journal_issues_url(article)
    jtitle = raze(article.journal.title)
    return nil unless jtitle

    journals_doc = CachedWebPage.get_cached_doc(:url => join_url, :grep => "soils")
    journals = journals_doc.search("div.content > h4 > strong > em")

    max_diff = 10
    match = nil

    journals.each do |journal|
      title = raze(journal.text)
      diff = String.diff_string(jtitle, title)

      if diff < max_diff
        max_diff = diff
        match = journal
      end
    end unless match

    join_url(match.parent.parent.next_sibling.next_sibling.at("a")['href'] + "/index") if match
  end

  def join_url(part = nil)
    return "https://www.soils.org/publications/" unless part
    URI.parse("https://www.soils.org/publications/").merge(part).to_s
  end
end
