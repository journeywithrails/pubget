class Publisher::CDC < Publisher::Base
  def issue_url(params= {})
    article = params[:article]
    "http://www.cdc.gov/eid/content/#{article.volume}/#{article.issue}/contents_v#{article.volume}n#{article.issue}.htm"
  end

  def pdf_url(params)
    article = params[:article]
    url = nil
    search_page, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://www.cdc.gov/search.do?queryText=allintitle:#{article.title}&subset=mmwr", :grep=>'cdc', :details=>true)

    if result = search_page.search('div#search-content > ul.results > li').first
      if link = result.at('a[text()="PDF Version"]')
        url = link['href'].strip.downcase
      end
    end

    url
  end
end