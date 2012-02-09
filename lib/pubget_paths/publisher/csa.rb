class Publisher::CSA < Publisher::Base

  def issue_url(params={})
    article = params[:article]
    "http://www.csa.com/htbin/dbrng.cgi?username=cgtry1&access=cgtry101&db=psycarticles-set-c&issn=#{article.journal.issn}&mode=all"
  end

  def openurl(params={})
    article = params[:article]
    transform = params[:transform]
    if article.get_doi(params)
      "http://www.csa.com/htbin/getfulltext.cgi?username=cgtry1&access=cgtry101&mode=html&db=psycarticles-set-c&doi=#{article.get_doi(params)}"
    else
      nil
    end
  end
end