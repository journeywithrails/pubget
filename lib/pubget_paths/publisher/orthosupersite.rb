class Publisher::Orthosupersite < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    search_page, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://www.orthosupersite.com/searchResults.aspx?partialfields=&cx=&q=#{article.title}&client=common_frontend&output=xml_no_dtd&proxystylesheet=CME_frontend&getfields=*&filter=0&sort=date&requiredfields=projectID%3A19&site=default_collection&x=7&y=12", :grep=>'orthosupersite', :details=>true)

    if results = search_page.search('div#mainCenter > div > span > div > p > a')
      max_diff = 10
      match = nil

      results.each do |res|
        diff = String.diff_string(article.title, res.text)
        if diff < max_diff
          max_diff = diff
          match = res
        end
      end

      article.url = URI.parse('http://www.orthosupersite.com/').merge(match['href']) if match
    end
  end
end