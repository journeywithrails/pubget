class Publisher::Molvis < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]

    if search_url = archive_url(article)
      doc, redirect_url = CachedWebPage.get_cached_doc(:url => search_url, :grep => 'molvis', :details => true)
      articles = doc.search("body > div > p")
      atitle = article.title.downcase.strip.gsub(/\.$/, '')
      max_diff = 5
      match = nil

      articles.each do |item|
        title = item.at('font > b').render_to_plain_text.downcase.strip.gsub(/\.$/, '')
        if atitle == title.downcase
          match = item
          break
        end
      end

      unless match
        articles.each do |item|
          title = item.at('font > b').render_to_plain_text
          diff = String.diff_string(atitle, title.downcase)

          if diff < max_diff
            match = item
            break
          end
        end
      end

      if match
        article_doc_link = match.at("font > a[text()='Full text']")['href']
        article_doc, redirect_url = CachedWebPage.get_cached_doc(:url => "http://www.molvis.org/molvis/#{article_doc_link}", :grep => 'molvis', :details => true)
        link = article_doc.at("body > div.links > div > p > a")
        url = link['href'] if link
      end
    end

    url
  end

  def archive_url(article)
    year = article.year.to_i
    return nil if year.zero?
    if year >= 1995 and year <= 1999
      "http://www.molvis.org/molvis/archive1.html#v#{1994 - year}"
    elsif year >= 2000 and year <= 2001
      "http://www.molvis.org/molvis/archive2.html#v#{1994 - year}"
    elsif year >= 2002
      "http://www.molvis.org/molvis/archive#{year - 1999}.html"
    end
  end
end