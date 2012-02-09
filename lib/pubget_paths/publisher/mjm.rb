class Publisher::Mjm < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]

    if request_url = issue_url(params)
      review_page = CachedWebPage.get_cached_doc(:url => request_url, :grep => 'e-mjm', :expired_in => 1.weeks)

      if results = review_page.search('div.entry > div.article > p > a')
        match = nil
        max_diff = 10
        title = article.title.downcase

        results.each do |result|
          diff = String.diff_string(title, result.text.downcase)
          if diff < max_diff
            max_diff = diff
            match = result
          end
        end
      end

      url = URI.parse(request_url).merge(match['href']) if match
    end

    url
  end

  def issue_url(params)
    article = params[:article]
    if article.year and article.volume and article.issue
      "http://www.e-mjm.org/#{article.year}/v#{article.volume}n#{article.issue}/index.html"
    else
      nil
    end
  end
end