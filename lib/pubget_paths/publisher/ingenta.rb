class Publisher::Ingenta < Publisher::Base
  def info
    count = 0
    csv_url = "http://www.ingentaconnect.com/titles/links.csv"
    @agent = HackedBrowser.new
    page = @agent.get(:url=>csv_url)
    content = page.body
    actions = {:added=>0, :updated=>0, :total=>0}
    content.split("\n").each do |line|
      if journal_match = /"([^"]+)","([^"]+)",(\d\d\d\d-\d\d\d[\dXx]),(\d\d\d\d-\d\d\d[\dXx]),(\d\d\d\d-\d\d\d\d),([^,]+),"([^"]+)"/.match(line)
        # Publisher,Title,PaperISSN/ISBN,ElectronicISSN,DateRange,Title-levelEasyLink
        publisher = journal_match[1]
        title = journal_match[2]
        pissn = journal_match[3]
        eissn = journal_match[4] == "0000-0000" ? nil : journal_match[4]
        base_url = journal_match[7]
        unless (publisher =~ /publisher/i)
          count += 1
          action = update_source("Ingenta", nil, pissn, eissn, title, nil, base_url, true, count)
          actions[:total] += 1
          if action == "added"
            actions[:added] += 1
          elsif action == "updated"
            actions[:updated] += 1
          end
        end
      end
    end
    CheckMonitor.checked("lister_info::ingenta", 1.months, "Updated lister for Ingenta", actions[:updated], actions[:added], actions[:total])
    puts actions.inspect
  end
  
  def pdf_url(params={})
    article = params[:article]
    article.url = search_by_title(article)
  end

  def search_by_title(article)
    atitle = raze(article.title)
    return nil unless atitle.present?

    search_url = join_url("/search?value1=#{CGI.escape(atitle)}&option1=title&pageSize=50")
    search_doc = CachedWebPage.get_cached_doc(:url => search_url, :grep => 'ingenta', :expired_in => 1.weeks)
    results = search_doc.search("form > div.greybg > div.data")
    bad_article_url = nil

    results.each do |result|
      link = result.at("div.ie5searchwrap > p > strong > a")
      next unless link

      title = raze(link.text)

      if atitle == title
        bad_article_url = join_url(link['href'])
        break
      end
    end

    return nil unless bad_article_url

    article_doc = CachedWebPage.get_cached_doc(:url => bad_article_url, :grep => 'ingenta')
    article_link = article_doc.at("div.linksoptions > ul > li > a[text()='ingentaconnect']")
    return nil unless article_link

    join_url(article_link['href'])
  end

  def join_url(part)
    URI.parse("http://www.ingentaconnect.com/").merge(part).to_s
  end
end