class Publisher::Ebsco < Publisher::Base
  
  def issue_url(params={})
    nil
  end
  
  def pdf_url(params={})
    article = params[:article]
    openurl(params)
  end
  
  def openurl(params)
    article = params[:article]
    transform = params[:transform]
    if article.exists_on_pubmed and (transform and transform.ebsco_medline == 1)
      "http://openurl.ebscohost.com/linksvc/linking.aspx?id=pmid:#{article.pmid}&genre=article"
    else
      issn_var = ""
      issn_val = ""
      if article.journal.eissn.blank?
        issn_var = "issn"
        issn_val = article.journal.pissn
      else
        issn_var = "eissn"
        issn_val = article.journal.eissn
      end
      return nil if article.pagination.blank? or article.volume.blank? or article.issue == "9999" or article.volume == "9999" or article.pagination == "NA"
      return "http://openurl.ebscohost.com/linksvc/linking.aspx?" +
        "genre=article&amp;sid=vendor:database&amp;#{issn_var}=#{issn_val}&" +
        "volume=#{article.volume}#{article.issue.blank? ? '' : ('&amp;issue=' + article.issue)}&amp;spage=#{article.start_page}"
    end
  end
end