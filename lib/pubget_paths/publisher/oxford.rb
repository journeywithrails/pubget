class Publisher::Oxford < Publisher::Highwire
  def info
    #from http://www.oxfordjournals.org/access_purchase/2009/institution_price_list.html
    @agent = WWW::Mechanize.new
    puts "getting oxford url"
    url = "http://www.oxfordjournals.org/access_purchase/2010/institution_price_list.html"
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true)
    
    count = 0
    trs = doc.search("tr")
    actions = {:added=>0, :updated=>0, :total=>0}
    puts "found #{trs.size} trs"
    trs.each do |tr|
      count = count + 1
      if tr.inner_html =~ /journal_title/
        tds = tr.search("td")
        title = tds[1].at("a").inner_text
        issn = tds[2].inner_text
        eissn = tds[3].inner_text
        if tds[1].at("a")
         base_url = tds[1].at("a")['href']
         action = update_journal("Oxford", nil, issn, eissn, title, nil, base_url, false, count, false)
         actions[:total] += 1
         if action == "added"
           actions[:added] += 1
         elsif action == "updated"
           actions[:updated] += 1
         end
        end
      end
    end
    CheckMonitor.checked("lister_info::oxford", 1.months, "Updated lister for Oxford", actions[:updated], actions[:added], actions[:total])
    
  end
  
  def issue_url(params)
    article = params[:article]
    base_url = article.journal.base_url
    volume = article.volume
    issue = article.issue

    if base_url.blank? or volume.blank? or issue.blank?
      nil
    elsif volume and issue
      "#{base_url}/content/#{article.volume}/#{article.issue}"
    end
  end

  def pdf_url(params)
    article = params[:article]
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :grep=>'oxfordjournals', :details=>true)

    puts "Trying to guess url..."
    url = guess_url(doc, article)

    unless url
      puts "No guess worked. Searching by title..."
      url = search_url_by_title(doc, article)
    end

    if url
      url = File.join(article.journal.base_url, url)
      url.gsub!(/\+html$/, "")
    end

    url
  end

  def search_url_by_title(doc, article)
    results = doc.search('div.toc-level > ul > li')

    max_diff = 10
    match = nil

    results.each do |result|
      title = result.at('h4.cit-title-group')
      atitle = article.title.downcase
      next unless title

      diff = String.diff_string(atitle, title.render_to_plain_text.downcase)
      if diff < max_diff
        max_diff = diff
        match = result
      end
    end

    if match
      a = match.at("div.cit-extra a[text()='Full Text (PDF)']")
      return a['href'] if a
    end

    nil
  end

  def guess_url(doc, article)
    guesses = [
      "/content/#{article.volume}/#{article.issue}/#{article.first_page}.full.pdf+html",
      "/content/#{article.volume}/#{article.issue}/#{article.last_page}.full.pdf+html"
    ]

    guesses.each do |guess|
      a = doc.at("a[@href='#{guess}']")
      return guess if a
    end

    nil
  end
end