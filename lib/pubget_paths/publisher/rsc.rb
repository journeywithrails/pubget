class Publisher::RSC < Publisher::Base

  def issue_url(params = {}, padding="")
    article = params[:article]
    key = article.journal.base_url.split("=").last
    "http://www.rsc.org/Publishing/Journals/#{key}/article.asp?Journal=#{key}&Volume=#{article.volume}&JournalCode=#{key}&SubYear=#{article.article_date.year}&type=Issue&Issue=#{padding}#{article.issue}"
  end
  
  def openurl(params={})
    if article.get_doi(params)
      "http://xlink.rsc.org/?DOI=#{article.get_doi.split('/').last}"
    else
      nil
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true, :grep=>'rsc')
     
    uri = URI.parse(redirect_url)
    lowest = 20 #get at least 15 but get the lowest
    path = nil
    link = nil   
      
    doc.search("strong").each do |strong|
      if strong.at("a")
        term1 = strong.render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = 1000
        begin
          diff = diff_string(term1, term2)
        rescue
        end
        if diff < lowest
          lowest = diff           
          href =  strong.at("a")['href']          
          agent = WWW::Mechanize.new
          page = agent.get(href)
          link_page = page.uri.to_s
          path = link_page.gsub("Content/ArticleLanding","content/pdf/article" )
        end
      end
    end
    path
  end
end