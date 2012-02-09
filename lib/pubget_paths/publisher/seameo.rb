class Publisher::Seameo < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]

    if journal_url = find_journal_url(article)
      url = find_on_page(article, journal_url)
    end

    url
  end

  def find_on_page(article, journal_url)
    journal_doc = CachedWebPage.get_cached_doc(:url => journal_url, :grep => 'seameo')

    if first_page = article.first_page
      article_item = journal_doc.at("table > tr > td[text()='#{first_page}']")
      link = article_item.parent.previous_sibling.children.first.at('a')
      title = link.render_to_plain_text.downcase
      atitle = article.title.downcase

      if String.diff_string(atitle, title) < 5
        url = join_url(link['href'])
      end
    end
  end

  def find_journal_url(article)
    issue = article.issue.to_i
    return nil unless issue

    year = article.year.to_i
    volume = article.volume.to_i
    year = 1969 + volume unless year if volume
    volume = year - 1969 unless volume if year
    return nil if not year or not volume

    d = ((year == 2001 and issue == 4) or (year > 2008)) ? '-' : '_'
    join_url("journal#{d}#{volume}#{d}#{issue}#{d}#{year}.html")
  end

  def join_url(part)
    URI.parse('http://www.tm.mahidol.ac.th/seameo/').merge(part).to_s
  end
end
