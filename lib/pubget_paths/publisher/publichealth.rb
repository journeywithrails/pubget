class Publisher::Publichealth < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    "http://www.publichealthreports.org/archives/issuecontents.cfm?Volume=#{article.volume}&Issue=#{article.issue}"
  end
  
  def pdf_url(params={})
    article = params[:article]
    nil
  end
  
end