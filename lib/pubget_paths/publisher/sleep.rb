class Publisher::Sleep < Publisher::Base
    
  def issue_url(params={})
    article = params[:article]
    article.journal.base_url
  end
  
  def pdf_url(params={})
    article = params[:article]
    
    path = nil
    unless path
      path = article.pubmed_central_path
    end
    path
  end
end