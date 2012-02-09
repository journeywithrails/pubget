class Publisher::Oie < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]
    article_url = issue_url(article)
    return nil unless article_url

    article_page = CachedWebPage.get_cached_doc(:url => article_url, :grep => 'oie')
    results = article_page.search('table.t_form > tr > td > ul > li')

    results.each do |reault|
      link = reault.at('a')
      next unless link

      link_text = link.render_to_plain_text
      url = "http://web.oie.int/boutique/extrait/#{link_text}" if link_text.scan(/.*\.pdf$/)
    end

    url
  end

  def issue_url(article)
    volume = (article.volume || (1991 + article.year) || nil).to_i
    issue = article.issue.to_i
    return if volume.zero? or issue.zero?

    archive_url = "http://www.oie.int/en/publications-and-documentation/scientific-and-technical-review-free-access/list-of-issues/"
    archive_page = CachedWebPage.get_cached_doc(:url => archive_url, :grep => 'oie')
    results = archive_page.search("div.csc-frame > p.bodytext")

    aissue_attr = "Vol. #{volume} (#{issue})"
    found_url = nil

    results.each do |result|
      issue_attr = result.render_to_plain_text.strip.scan(/Vol.\s\d+\s\(\d+\)/).first

      if issue_attr and issue_attr == aissue_attr and link = result.at('a')
        found_url = link['href']
        break
      end
    end

    return nil unless found_url

    issues_page = CachedWebPage.get_cached_doc(:url => found_url, :grep => 'oie')
    results = issues_page.search("div.t_form > ul > li > a")

    atitle = raze(article.title)

    results.each do |result|
      next unless title_elem = result.at('span')
      title = raze(title_elem.render_to_plain_text)

      return "http://web.oie.int/boutique/#{result['href']}" if atitle == title
    end
  end
end