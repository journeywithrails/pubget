class Publisher::MIT < Publisher::Atypon
  def issue_url (params= {})
     article = params[:article]
    "#{article.journal.base_url.gsub('loi','toc')}/#{article.volume}/#{article.issue}"
  end

  def openurl(params={})
    article = params[:article]
    doi = article.get_doi(params)
    if doi
      "http://www.mitpressjournals.org/doi/abs/#{doi}"
    else
      nil
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    doi = get_doi(article)
    if doi
      path = "http://www.mitpressjournals.org/doi/pdf/#{doi}"
    end
    
    unless path
      doc = parse_html(CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'mit'))
      lowest = 20 #get at least 10 but get the lowest
      term2 = article.title.downcase
      if term2 =~ /:/
        term2 = term2.split(":").first
      end
      doc.search("table.articleEntry").each do |table|
      
        if table.at("div.arttitle")
          term1 = table.at("div.arttitle").render_to_plain_text.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            table.search("a").each do |a|
              path = "http://www.mitpressjournals.org#{CGI.unescape(a['href'])}" if a.render_to_plain_text =~ /PDF/i
            end
          end
        end
      end
    end
    path
  end
end