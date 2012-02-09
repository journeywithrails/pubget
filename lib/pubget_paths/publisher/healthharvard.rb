class Publisher::Healthharvard < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    search_page, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://www.health.harvard.edu/search/?q=#{article.title}&as_occt=title&output=xml_no_dtd&site=health&client=health&proxystylesheet=health", :grep=>'orthosupersite', :details=>true)

    if search_page and results = search_page.search('div#columns > div#main > div > p > a')
      match = nil

      if results.size == 1
        match = results.first
      else
        max_diff = 10
        title = article.title

        results.each do |res|
          diff = String.diff_string(title, res.text.gsub(/ \- Harvard .*/, ''))
          if diff < max_diff
            max_diff = diff
            match = res
          end
        end
      end

      article.url = URI.parse('http://www.health.harvard.edu/').merge(match['href']) if match
    end

    nil
  end
end