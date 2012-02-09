class Publisher::Krakow < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    "http://www.jpp.krakow.pl/journal/archive/#{article.article_date.strftime('%m%y')}/index#{article.article_date.strftime('%m%y')}.html"
  end
  
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = "http://www.jpp.krakow.pl/journal/archive/#{article.article_date.strftime('%m%y')}/pdf/#{article.start_page}_#{article.article_date.strftime('%m%y')}_article.pdf"
    path
  end
  
end