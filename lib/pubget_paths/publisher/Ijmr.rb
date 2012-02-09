class Publisher::Ijmr < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]

    if query_url = build_query(article)
      doc = CachedWebPage.get_cached_doc(:url => query_url, :grep => 'ijmr', :expired_in => 1.weeks)
      results = doc.search("table[@width='95%'] > tr > td > table > tr")

      atitle = raze(article.title)
      match = nil

      results.each do |result|
        title_col = result.at('td.pl > p > b')
        next unless title_col

        title = raze(title_col.render_to_plain_text)
        match = result and break if atitle == title
      end

      unless match
        max_diff = 10

        results.each do |result|
          title_col = result.at('td.pl > p > b')
          next unless title_col

          title = raze(title_col.render_to_plain_text)
          diff = String.diff_string(atitle, title)

          if diff < max_diff
            max_diff = diff
            match = result
          end
        end
      end

      if match
        link = match.at("td > b > font > a")
        url = join_url(link['href']) if link
      end
    end

    url
  end

  def build_query(article)
    year = article.year
    volume = article.volume
    return nil if not year and not volume

    join_url("/icmrsql/journals/journalList.asp?year=#{year}&volumeno=#{volume}")
  end

  def join_url(part)
    URI.parse('http://www.icmr.nic.in/').merge(part).to_s
  end
end