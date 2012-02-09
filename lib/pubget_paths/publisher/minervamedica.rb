class Publisher::Minervamedica < Publisher::Base

  def info
    publisher = "minervamedica"
 
    puts "working on minervamedica"
    
    journal_list_url = "http://www.minervamedica.it/en/journals/index.php?select=2"
    journal_list = CachedWebPage.get_cached_doc(:url=>journal_list_url)
    
    uri = URI.parse(journal_list_url)
    
    count = 0
    journal_list.search("p.m2 a").each do |a|
      count += 1
      journal_url = "#{uri.merge(a['href'])}"
      journal_doc, baseurl = CachedWebPage.get_cached_doc(:url=>journal_url, :details=>true)
      
      title = journal_doc.at("title").inner_text.split("-").first.strip
      issn = nil
      if issn_match = /P\.ISSN\s+([0-9]{4}\-[0-9]{3}[0-9xX]{1})/.match(journal_doc.inner_text)
        issn = issn_match[1]
      end
      eissn = nil
      if eissn_match = /E\.ISSN\s+([0-9]{4}\-[0-9]{3}[0-9xX]{1})/.match(journal_doc.inner_text)
        eissn = eissn_match[1]
      end
      update_journal(publisher, nil, issn, eissn, title, nil, baseurl, true, count)
    end
  end
  
  def pdf_url(params)
    article = params[:article]
    
    @cw = CachedWebPage.new
    referer_url = get_linkouts(article).first
    abstract_doc, redirect_url = @cw.get_cached_doc(:url=>referer_url, :details=>true)
    
    ft_a = abstract_doc.at("a[text()='FULL TEXT']")
    path = nil
    if a_match = /freedownload.php\?cod=(.+)$/.match(ft_a['href'])
      path = "http://www.minervamedica.it/en/getfreepdf.php?cod=#{a_match[1]}"
    end
    
    article.pdf_url = path
    
    # this is attachment not inline so only show PDF if open and we can serve it
    path = article.cache_pdf(false, {:referer => referer_url, :need_cookie_from_referer => true})
    path
  end
end