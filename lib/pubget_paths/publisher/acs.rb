class Publisher::ACS < Publisher::Atypon
  
  def issue_url(params={})
    article = params[:article]
    if article.journal.base_url
      "#{article.journal.base_url.gsub('journal', 'toc')}#{article.volume}/#{article.issue}"
    end
  end
  
  def openurl(params={})
    article = params[:article]
    transform = params[:transform]
    if article.get_doi(params)
      "http://pubs.acs.org/doi/full/#{article.get_doi(params)}"
    else
      issue_url(params)
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    if article.get_doi(params)
      #debugger
      "http://pubs.acs.org/doi/pdf/#{article.get_doi(params)}"
    else
      nil
    end
  end

end
