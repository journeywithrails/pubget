class Publisher::APS < Publisher::Scitation
  
  def pdf_url(params={})
    # from http://link.aps.org/
    article = params[:article]
    params[:use_pigeon] ||= false
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
    uri = URI.parse(redirect_url)
    lowest = 15
    path = nil
    doc.search("div.aps-toc-articleinfo").each do |div|
      if div.at("strong")
        term1 = div.at("strong").render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          div.search("a").each do |a|
            if a.render_to_plain_text =~ /PDF/
              path = uri.merge(a['href']).to_s
            end
          end
        end
      end
    end
    unless path
      key = "#{uri.host.split(".").first.gsub('-','')}"
      
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://link.aps.org/abstract/#{key.upcase}/v#{article.volume}/p#{article.pagination}", :details=>true, :grep=>"aps")
      uri = URI.parse(redirect_url)
      deldiv = doc.at("div.aps-deliverablesbar")
      if deldiv
        deldiv.search("a").each do |a|
          if a.render_to_plain_text =~ /PDF/
            path = uri.merge(a['href']).to_s if a.render_to_plain_text =~ /PDF/
          end
        end
      end
    end
    unless path
      key = "#{uri.host.split(".").first.gsub('-','')}"
      if key and article.volume and article.start_page
        path = "http://#{key}.aps.org/pdf/#{key.upcase}/v#{article.volume}/p#{article.start_page}"
      end
    end
    return path
  end
  
  def issue_url(params= {})
    article = params[:article]
    uri = URI.parse(article.journal.base_url)
    base_url = article.journal.base_url
    key = "#{uri.host.split(".").first.gsub('-','')}"
    issue = article.issue
    
    if m = article.issue.match(/^(\d+) Pt/)
      issue = m[1]
    end
    if letter = article.journal.title.match(/\W[A-E]\W/)
      key = "pr" + letter[0][1,1].downcase
      base_url = base_url.gsub("prola", key)
      "#{base_url}toc/#{key.upcase}/v#{article.volume}/i#{issue}"
    else
      "#{base_url}toc/#{key.upcase}/v#{article.volume}/i#{issue}"
    end
  end
    
end