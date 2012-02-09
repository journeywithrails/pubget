class Publisher::IOP < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    "http://iopscience.iop.org/#{article.journal.pissn}/#{article.volume}/#{article.issue}"
  end
  
  def openurl(doi)
    parts = doi.split('/')
    doi_last = "#{parts[1]}/#{parts[2]}/#{parts[3]}/#{parts[4]}/pdf/#{parts[1]}_#{parts[2]}_#{parts[3]}_#{parts[4]}.pdf"
    doi_url= "http://iopscience.iop.org/#{doi_last}"
  end

  def pdf_url(params={})
    path = nil
    article = params[:article]
    doi = article.get_doi
    
    #If there is a DOI, get URL that way
    if doi!=nil
      path = openurl(doi)
    elsif article.title!=nil
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
      lowest = 10      #get at least 10 but get the lowest
      doc.search("div.paperEntry").each do |div|
        div.search("a.title").each do |x|   
          dif=11
          term1 = x.content.strip
          term2 = article.title
          diff = diff_string(term1, term2)
          if diff<lowest
            lowest=diff 
            doi = div.search("span.viewingLinks").search("a.link").first.attributes['href'].value
            parts = doi.split('/')
            doi_last = "#{parts[1]}/#{parts[2]}/#{parts[3]}/#{parts[4]}/pdf/#{parts[1]}_#{parts[2]}_#{parts[3]}_#{parts[4]}.pdf"
            path= "http://iopscience.iop.org/#{doi_last}"
          end
        end
      end  
    end

    path
  end

end