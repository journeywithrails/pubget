class Publisher::Schattauer < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_title(article)

    url
  end

  def search_by_title(article)
    year = article.year
    volume = article.volume
    issue = article.issue
    return nil if year.blank? or volume.blank? or issue.blank?

    archive_url = archive_url(article)
    return nil unless url = parse_archive_recursive(archive_url, year, volume, issue)

    parse_issues_recursive(article, url)
  end

  def parse_issues_recursive(article, issue_url)
    issues_page = CachedWebPage.get_cached_doc(:url => issue_url, :grep => 'schattauer')
    results = issues_page.search("div.schattauerManuscriptTitle")
    atitle = raze(article.title)
    match = nil

    results.each do |result|
      title = raze(result.render_to_plain_text)

      if atitle == title
        match = result
        break
      end
    end
    max_diff = 10

    results.each do |result|
      title = raze(result.render_to_plain_text)

      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = result
      end
    end unless match

    if match
      return match.at("a")['href'].gsub(/issue\/\d+\/manuscript/, 'issue/special/manuscript').gsub(/show\.html$/, 'download.html')
    end

    if next_page_link = issues_page.at("td.schattauerPagerTable-Next-Active > div > a")
      next_page_url = next_page_link['href']
      puts "No issues found. Switching to the next page..."

      return parse_issues_recursive(article, next_page_url)
    end

    nil
  end

  def parse_archive_recursive(doc_url, year, volume, issue)
    archive_page = CachedWebPage.get_cached_doc(:url => doc_url, :grep => 'schattauer')
    results = []

    if start_point = archive_page.at("div.schattauerTabContent > h2[text()='#{year}']")
      results = start_point.next_sibling.search("tr")
    end

    results.each do |result|
      archive_link = result.at("td > a")
      link_text = archive_link.render_to_plain_text

      if link_text.scan(/#{volume}\/#{issue}/).any?
        return archive_link['href']
      end
    end

    if next_page_link = archive_page.at("td.schattauerPagerTable-Next-Active > div > a")
      next_page_url = next_page_link['href']
      puts "No archive found. Switching to the next page..."

      return parse_archive_recursive(next_page_url, year, volume, issue)
    end

    nil
  end

  def archive_url(article)
    join_url("#{article.journal.title.downcase.gsub(/\s/, '-')}/contents/archive.html")
  end

  def join_url(part)
    URI.parse('http://www.schattauer.de/de/magazine/uebersicht/zeitschriften-a-z/').merge(part).to_s
  end
end