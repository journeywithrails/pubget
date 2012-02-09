class Publisher::MLA < Publisher::Base
  
  def info
    title = "Journal of the Medical Library Association : JMLA"
    base_url = "http://www.mlanet.org/publications/jmla/index.html"
    update_journal("MLA", nil, "1536-5050", "1558-9439", title, nil, base_url,
      nil, 1, uncertain_title=false)
    CheckMonitor.checked("lister_info::MLA", 1.years, "Updated lister for MLA", 1,0,1)
  end
  
  def issue_url(params={})
    article = params[:article]
    article.journal.base_url
  end
  
  def pdf_url(params={})
    central_path(params)
  end
  
  def central_path(params={})
    article = params[:article]
    path = nil
    unless article.get_pmcid.blank?
      path = "http://www.pubmedcentral.nih.gov/picrender.fcgi?artid=#{article.get_pmcid}&blobtype=pdf"
      asset_path = path
    end
    path
  end
end