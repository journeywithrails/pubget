class Publisher::APA < Publisher::Base
  
  def info
    update_journal("APA", nil, "0004-9514", nil, "The Australian journal of physiotherapy", nil, " http://physiotherapy.asn.au/index.php/quality-practice/ajp/ajp-archive ",
         true, 1)
  end
  
  def pdf_url(params={})
    article = params[:article]
    path = nil
    
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
    uri = URI.parse(redirect_url)
    lowest = 15
    path = nil
    #TODO: we could do better here because they lump all correspondance together at the end - PubMed breaks out the letters (so need to search on page)
    doc.search("a").each do |a|
      if a['href'] =~ /\.pdf$/
        term1 = a.render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          path = uri.merge(a['href']).to_s
        end
      end
    end
    
    path
  end
  
  def issue_url(params)
    article = params[:article]
    "http://ajp.physiotherapy.asn.au/AJP/vol_#{article.volume}/#{article.issue}/volume#{article.volume}_number#{article.issue}.cfm"
  end
  
end