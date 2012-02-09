class Publisher::Future < Publisher::Literatumonline
  
  def issue_url(params={})
    article = params[:article]
     "#{article.journal.base_url.gsub('loi','toc')}/#{article.volume}/#{article.issue}"
  end
  
  def openurl(params={})
    article = params[:article]
    doi = article.get_doi(params)
    if doi
      "http://www.futuremedicine.com/doi/abs/#{doi}"
    else
      nil
    end
  end
end