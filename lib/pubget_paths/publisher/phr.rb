class Publisher::PHR < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    nil
  end
  
  def pdf_url(params={})
    article = params[:article]
    nil
  end
end