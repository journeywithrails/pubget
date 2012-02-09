class Publisher::Nefrologia < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_doi(article)

    url
  end

  def search_by_doi(article)
    return nil unless adoi = article.doi

    url = "http://dx.doi.org/#{adoi}"
    article_doc_es, redirect_url = CachedWebPage.get_cached_doc(:url => url, :details => true)
    url = redirect_url.gsub(/idlangart=ES/, 'idlangart=EN')
    article_doc_en = CachedWebPage.get_cached_doc(:url => url)

    links = article_doc_en.search("div#centrado > table > tr > td > div > div > a")

    links.each do |link|
      text = link.render_to_plain_text.strip
      return join_url(link['href']) if text =~ /Ver \/ Descargar PDF/
    end
  end

  def join_url(part)
    URI.parse("http://www.revistanefrologia.com/").merge(part).to_s
  end
end