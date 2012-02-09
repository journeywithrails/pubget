class Publisher::AAFP < Publisher::Base
  
  def issue_url(params= {})
     article = params[:article]
      "http://www.aafp.org/afp/AFPprinter/#{article.article_date.strftime('%Y%m%d')}/"
   end
   
   def pdf_url(params={})
      article = params[:article]
      params[:use_pigeon] ||= false
      
      return nil if article.article_date.blank?
      
      p, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://www.aafp.org/afp/#{article.article_date.year}/#{article.article_date.strftime('%m%d')}/p#{article.start_page}.html", :details=>true)
      uri = URI.parse(redirect_url)
      path = nil
      
      a = p.at("a[text()='Download PDF']")
      path = uri.merge(a['href']).to_s if a
      
      if path.blank?
        #Try PMC if all else fails
        path = pubmed_central_path(article)
      end
      path
   end
   
end
class Publisher::Aafp < Publisher::AAFP
end