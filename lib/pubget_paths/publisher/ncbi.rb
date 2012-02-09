class Publisher::Ncbi < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]

    if article.cached_pdf_url
      doc, redirect_url = CachedWebPage.get_cached_doc(:url => article.cached_pdf_url, :details => true, :grep => 'ncbi')
      url = redirect_url if redirect_url.scan(/^.*\.pdf/i)
    end

    if not url and article.pmcid
      host = "http://www.ncbi.nlm.nih.gov/"
      abstract_page = "#{host}pmc/articles/#{article.pmcid}"
      doc, redirect_url = CachedWebPage.get_cached_doc(:url => abstract_page, :details => true, :grep => 'ncbi')
      title = doc.search("div.front-matter-section > div.fm-title")
      if title
        title = title.text.downcase
        diff = String.diff_string(article.title.downcase, title)
        if (diff < 10)
          links = doc.search("td.format-menu > ul > li > a")
          links.each do |link|
            url = link['href'] if link.text.scan(/PDF\s\(.*\)/)
          end
          url = URI.parse(host).merge(url) if url and url.scan(/^http:\/\//)
        end
      end
    end

    url
  end
end