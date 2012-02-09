class Publisher::Pathexo < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]
    bulletin_label = build_label(article)

    if bulletin_label
      bulletins_doc = CachedWebPage.get_cached_doc(:url => join_url("bull_sommaire.php?L=1"), :grep => 'pathexo')
      bulletin_link = bulletins_doc.at("td.Col > table > tr > td > a.important[text()='#{bulletin_label}']")
      match = nil

      if bulletin_link
        articles_doc = CachedWebPage.get_cached_doc(:url => join_url(bulletin_link['href']), :grep => 'pathexo')
        titles_en = articles_doc.search('div.CentreBoxBodyText p.titreEN')
        titles_fr = articles_doc.search('div.CentreBoxBodyText p.titreFR')
        match = search_by_title(article.title, titles_en)
        match = search_by_title(article.title, titles_fr) unless match
      end

      if match
        link = match.next_sibling.next_sibling.at('a.important')
        url = join_url(link['href'])
      end
    end

    url
  end

  def search_by_title(atitle, titles)
    atitle = atitle.downcase.strip.gsub(/\[|\]|\.$/, '')

    titles.each do |title|
      return title if atitle == title.text.downcase.strip.gsub(/\.$/, '')
    end

    max_diff = 10
    match = nil

    titles.each do |title|
      diff = String.diff_string(atitle, title.text.downcase.strip)
      if diff < max_diff
        max_diff = diff
        match = title
      end
    end

    match
  end

  def join_url(part)
    URI.parse('http://www.pathexo.fr/').merge(part).to_s
  end

  def build_label(article)
    year = article.year
    volume = article.volume
    issue = article.issue

    return nil if not year or not volume or not issue

    "#{year}, T#{volume}-#{issue}"
  end
end