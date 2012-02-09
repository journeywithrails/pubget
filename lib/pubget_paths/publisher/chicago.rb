class Publisher::Chicago < Publisher::Atypon

  def issue_url (params= {})
    article = params[:article]
    if article.volume != ""
      "#{article.journal.base_url.gsub('current','')}#{article.article_date.year}/#{article.volume}/#{article.issue}"
    else
      "#{article.journal.base_url.gsub('current','')}0/0"
    end
  end

  def openurl(params={})
    article = params[:article]
    doi = article.get_doi(params)
    if doi
      "http://www.journals.uchicago.edu/doi/abs/#{doi}"
    else
      nil
    end
  end

  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    if doi = article.get_doi(params)
      return "#{article.journal.journal_host}/doi/pdf/#{doi}"
    end
    path = nil

    doc, redirect_url = CachedWebPage.get_cached_doc(:details=>true, :url=>issue_url(params))
    uri = URI.parse(redirect_url)
    lowest = 10 #get at least 10 but get the lowest
    path = nil
    div = doc.at("#journalArticleListing")
    if div
      div.search("li").each do |li|
        unless li.render_to_plain_text.blank?
          term1 = li.at("label").render_to_plain_text.downcase
          term2 = title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            li.at("div.articleLinks").search("a").each do |a|
              doi =  a['href'].gsub("/pdf/",":")
              path = uri.merge(a['href']).to_s if a.render_to_plain_text =~ /PDF/
            end
          end
        end
      end
    end
    path
  end
end