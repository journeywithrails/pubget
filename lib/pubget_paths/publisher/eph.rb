class Publisher::EPH < Publisher::Base

  def info
    update_journal("EPH", "eph_without_linkout", "0091-6765", "1552-9924", "Environmental Health Perspectives", nil, "http://www.ehponline.org/ehp/",
         true, 1)
  end

  def issue_url(params= {})
    article = params[:article]
    url = "http://www.ehponline.org/docs/#{article.article_date.year}/#{article.volume}-#{article.issue}/toc.html"
    url
  end
  
  
  def openurl(params={})
    article = params[:article]
    doi_url = "http://ehp03.niehs.nih.gov/article/fetchObject.action;?uri=info:doi/#{article.get_doi()}&representation=PDF"
  end
  
  def pdf_url(params={})
    article = params[:article]
    puts issue_url(:article=>article)
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
    
    path = nil
    if article.doi!=nil
      path = openurl(article.doi)
    else
      lowest = 10 #get at least 10 but get the lowest
      term1 = article.title.downcase
      #Scrapes DOI from issue page
      doc.search("div.article").each do |div|
        div.search("h3").each do |h|
          term2 = h.content.downcase
          diff = diff_string(term1,term2)
          if diff<lowest
            lowest=diff
            article_url = div.search("iframe").first.attributes["src"].content
            get_doi = /doi\/(.*)/
            doi = article_url.scan(get_doi).to_s
            path = openurl(doi)
          end
        end  
      end   
    end
    path
  end
end