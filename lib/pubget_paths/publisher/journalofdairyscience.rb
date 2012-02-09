class Publisher::Journalofdairyscience < Publisher::Base
  
  def pdf_url(params={})    
    article = params[:article]   
    path = get_path("search_doi", article.doi) unless article.doi.blank?
    path = get_path("search_text1", article.sort_title) if path.blank? && !article.sort_title.blank?    
    path
  end
  
  
  def get_path(name_search, value)
    path = ""
    agent = WWW::Mechanize.new
    page = agent.get("http://www.journalofdairyscience.org/search/advanced?searchDisciplineField=journal")
    search_form = page.forms[1]
    search_form[name_search] = value
    search_form["search_within1"] = "ti"
    page = agent.submit search_form
    contents = page.search(".//a[@class='viewoption']")
    
    contents.each do |content|
      if content.text.include? "PDF"
        path = content['href']
      end
    end    
    path
  end
  
end