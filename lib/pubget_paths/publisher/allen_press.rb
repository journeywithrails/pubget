class Publisher::AllenPress < Publisher::Atypon
  
  def issue_url(params= {})
    article = params[:article]
    m = article.journal.base_url.match(/^(.+?)&volume.+?$/)
    base = m[1] if m
    m = article.issue.match(/^(\d+)$/)
    issue = m ? m[1] : article.issue
    "#{base ? base : article.journal.base_url}&volume=#{article.volume}&issue=#{article.issue}"
  end
  
  def openurl(params={})
    article = params[:article]
    "#{issue_url(params).gsub('get-toc','get-document')}&page=#{article.start_page}" if article.start_page
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    issn = article.pissn

    if article.get_doi(params)
      path = URI.parse(article.journal.base_url).merge("/doi/pdf/#{CGI.escape(article.get_doi(params))}").to_s
    end

    unless path
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true, :expires_in=>6.months)
      uri = URI.parse(redirect_url)
      lowest = 10 #get at least 10 but get the lowest
      title = article.title.downcase
      doc.search("table.articleEntry tr").each do |tr|
        term2 = tr.at("div.art_title").inner_text.downcase

        diff = diff_string(title, term2)
        if diff < lowest
          lowest = diff
          doi = tr.at("input")['value']
          article.doi = doi
          path = uri.merge("/doi/pdf/#{CGI.escape(doi)}").to_s
        end
      end
    end

    unless path
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>openurl(params), :details=>true, :expires_in=>6.months)
      if redirect_url =~ /\/doi\/full\//
        path = redirect_url.gsub("/full/", "/pdf/")
      end
    end

    path
  end

end