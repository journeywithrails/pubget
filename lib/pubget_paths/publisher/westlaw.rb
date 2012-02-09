class Publisher::Westlaw < Publisher::Base
  
  def openurl(params={})
    article = params[:article]
    doi = article.get_doi(params)
    if doi
      "http://dx.doi.org/#{doi}"
    else
      nil
    end
  end
end