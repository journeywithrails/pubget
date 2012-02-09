class Publisher::Proquest < Publisher::Base

  def source_name
      "proquest"
  end
  

  def info
  # journals_list = CachedWebPage.get_cached_url(:url => "http://www.proquest.com/en-US/products/titlelists/default.shtml?format=xls")
  puts "Rajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj--------------------------------------------------"
  end


  def issue_url(params={})
    article = params[:article]
    "http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqd&rft_val_fmt=info:ofi:fmt:kev:mtx:journal&jtitle=#{article.journal_title}&issn=#{article.issn}&svc_id=xri:pqil:context=title"
  end
  
  def openurl(params={})
    article = params[:article]
    "http://gateway.proquest.com/openurl?ctx_ver=Z39.88-2004&res_id=xri:pqd&rft_val_fmt=info:ofi:fmt:kev:mtx:journal&genre= article&jtitle=#{article.journal_title}&issn=#{article.issn}&atitle=#{article.title}&date=#{article.article_date}&volume=#{article.volume}&issue=#{article.issue}&spage=#{article.start_page}"
  end
  
  def pdf_url(params={})
    openurl(params)
  end

 
end