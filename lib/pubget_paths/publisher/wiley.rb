class Publisher::Wiley < Publisher::Base

  def info
    rows = FasterCSV.flexible_import("http://media.wiley.com/assets/2251/33/all_Wiley-Blackwell_journals_2011.xls")
    
    count = 0
    rows.each do |row|
      # 0. Journal Code
      # 1. Print ISSN
      # 2. Electronic ISSN
      # 3. Journal DOI
      # 4. Journal full title
      # 5. Wiley InterScience Journal Homepage URL 
      # 6. Wiley Online Library Journal Homepage URL
      # 7. Wiley Online Library Journal List of Issues Page URL 
      # 8. General Subject Category
      # 9. Primary Subject Area
      # 10. Original Company
      # 11. Print/Online or Print + Online
      # 12. External notes
      # 13. Full Collection
      # 14. STM Collection
      # 15. SSH Collection
      # 16. Medicine & Nursing Collection
      # 17. Not in any Collections
      # 18. Collection Start year / Start year for Current Sub
      # 19. Collection Start Volume / Start Vol for current Sub
      # 20. 2010 Volume
      # 21. 2010 Issues
      # 22. Year
      # 23. Backfile Start Year
      # 24. Backfile Start Volume
      # 25. Backfile Start Issue
      # 26. Backfile End Year
      # 27. Backfile End Volume
      # 28. Backfile End Issue
      # 29. RSS feed URL on Wiley InterScience
      # 30. RSS feed URL on Wiley Online Library
      # 31. Online Open
      # 32. Opt-in Titles for 2010
      # 33. Online Open Ord form link
      # 34. Author Guidelines link
      # 35. Open Access content
      # 36. Society name
      # 37. ISI Impact Factor
      
      if row and row.size > 33
        pissn = (row[1] =~ /\d\d\d\d\-\d\d\d[Xx\d]/) ?  row[1] : nil
        eissn = (row[2] =~ /\d\d\d\d\-\d\d\d[Xx\d]/) ?  row[2] : nil
        if pissn or eissn
          count += 1
          title = row[4].titleize
          base_url = row[6]
          open_acces_embargo = row[35]
          start_date = row[18].blank? ? nil : Date.date_from_string(row[18]) 
          impact_factor = row[37]
          begin
            update_journal("Wiley", nil, pissn, eissn, title, nil, base_url,
              nil, count, uncertain_title=false, nil, start_date, nil)
          rescue JournalWithIssnAlreadyExists
            puts $!.message
          end
        end
      end
    end

  end
  
  def get_wiley_doi(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    #Get the issue and find the DOI in there
    return article.doi if params[:inrequest]
    if article.get_doi().present?
      return article.get_doi()
    else
      begin
        return nil unless issue_url(params)
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
        puts "Got issue at: #{redirect_url}"
        if doc.at("title").inner_text =~ /Error/
          if joid_match = /journal\/([\d]+)\/home/.match(article.journal.base_url)
            year_url = "http://www3.interscience.wiley.com/journal/jtocgroupexpand?pISSN=#{article.journal.primary_issn}&joid=#{joid_match[1]}&year=#{article.year}"
            ydoc, redirect_url = CachedWebPage.get_cached_doc(:url=>year_url, :details=>true, :expires_in=>((Date.today.year == article.year.to_i) ? 1.week : 1.year))
            uri = URI.parse(redirect_url)
            ydoc.search('a').each do |a|
              if vol_iss_match = /Volume ([^\)]+) Issue ([^\)]+)/.match(a.inner_text)
                volume = vol_iss_match[1]
                issue = vol_iss_match[2]
                if (volume == article.volume) and (issue == article.issue)
                  doc, redirect_url = CachedWebPage.get_cached_doc(:url=>uri.merge(a['href']).to_s, :details=>true)
                end
              end
            end
          end
        end

        puts "doc: #{doc.class}"
        lowest = 10 #get at least 10 but get the lowest
        term2 = article.title ? article.title.downcase : ""
        #puts "title: #{term2}"
        doc.search("//div[@class='citation tocArticle']/a").each do |a|

        if term_match = /(.*) \(.*\)/.match(a.content)
          term1 = term_match[1]
          diff = diff_string(term1, term2)
            if diff < lowest
              #debugger
              lowest = diff
              doi = a.parent.search("p").last.inner_text.split(/DOI:[^1]+/).last
              unless doi.blank?
                article.doi = doi
                puts "Set DOI: #{article.doi}"
              end
            end
          end
        end
      rescue
        article.pdf_unavailable = Date.today
      end
      return article.get_doi()
    end
  end

  def issue_url(params= {})
    article = params[:article]
    if article.journal.eissn.present?
      "http://onlinelibrary.wiley.com/resolve/openurl?genre=issue&sid=vendor:database&eissn=#{article.journal.eissn}&volume=#{article.volume}#{article.issue.blank? ? '' : ('&issue=' + article.issue)}"
    elsif article.journal.pissn.present?
      "http://onlinelibrary.wiley.com/resolve/openurl?genre=issue&sid=vendor:database&issn=#{article.journal.pissn}&volume=#{article.volume}#{article.issue.blank? ? '' : ('&issue=' + article.issue)}"
    end
  end

  def openurl(params)
    article = params[:article]
    issn_var = ""
    issn_val = ""
    if article.journal.eissn.blank?
      issn_var = "issn"
      issn_val = article.journal.pissn
    else
      issn_var = "eissn"
      issn_val = article.journal.eissn
    end
    page = "#{article.pagination_long(true)}"
    "http://onlinelibrary.wiley.com/resolve/openurl?" +
      "genre=article&amp;sid=vendor:database&amp;#{issn_var}=#{issn_val}&amp;" +
      "volume=#{article.volume}#{article.issue.blank? ? '' : ('&amp;issue=' + article.issue)}&amp;pages=#{page.gsub(/\s/,'')}"
  end

  def searchurl(params={})
    article = params[:article]
    issue_url(params)
  end

  def pdf_url(params={})
    article = params[:article]
    path = nil
    # Don't use jstor and non wiley dois
    if not article.get_doi(params).blank?
      path = "http://onlinelibrary.wiley.com/doi/#{article.get_doi(params)}/pdf"
    else
      wiley_doi = get_wiley_doi(params)
      if wiley_doi.present? and wiley_doi !~ /^10\.(2307|1017)/
        path = "http://onlinelibrary.wiley.com/doi/#{article.get_doi(params)}/pdf"
      elsif article.journal.categories.any? and article.journal.title
        begin
          puts "Searching through web pages"
          path = search_by_title(article)
        rescue
        end
      else
        if article.journal.eissn.blank?
          issn_var = "issn"
          issn_val = article.journal.pissn
        else
          issn_var = "eissn"
          issn_val = article.journal.eissn
        end

        page = "#{article.pagination_long(true)}"
        path = "http://onlinelibrary.wiley.com/resolve/openurl?" +
          "genre=article&amp;sid=vendor:database&amp;#{issn_var}=#{issn_val}&amp;" +
          "volume=#{article.volume}#{article.issue.blank? ? '' : ('&amp;issue=' + article.issue)}&amp;pages=#{article.pagination.gsub(/\s/,'')}&amp;" +
          "svc.format=text/pdf"
      end
    end
    path
  end

  def search_by_title(article)
    url = search_issue_url(article)
    return nil unless url

    issues_doc = CachedWebPage.get_cached_doc(:url => url, :grep => "wiley")
    results = issues_doc.search("ol#issueTocGroups > li div.tocArticle > a")
    atitle = "#{raze(article.title)} (pages #{article.pagination_long(true).gsub(/-/, '—')}"

    max_diff = 10
    match = nil

    results.each do |link|
      title = raze(link.render_to_plain_text)
      diff = String.diff_string(atitle, title)

      if diff < max_diff
        max_diff = diff
        match = link
      end
    end

    return nil unless match

    links = match.parent.search("ul.productMenu > li > a")

    links.each do |link|
      text = link.render_to_plain_text
      return join_url(link['href']) if text.scan(/PDF\(\w+\)/).any?
    end

    nil
  end

  def search_issue_url(article)
    year = article.year
    volume = article.volume
    issue = article.issue
    return nil if not year or not volume or not issue

    journal_url = find_journal_url(article)
    return nil unless journal_url

    journal_doc = CachedWebPage.get_cached_doc(:url => join_url(journal_url), :grep => "wiley")
    current_link = journal_doc.at("p.issue > span.currentIssue").next_sibling
    return nil unless current_link

    token = ".#{year}.#{volume}.issue-#{issue}"
    url = current_link['href'].gsub(/\.\d{4}.\d+.issue-\d+/, token)
    join_url(url)
  end

  def find_journal_url(article)
    jcategory = article.journal.categories.first
    main_doc = CachedWebPage.get_cached_doc(:url => join_url, :grep => "wiley")
    category_link_span = main_doc.at("div#subjectBrowse div > ol > li > a > span[text()='#{jcategory}']")
    return nil unless category_link_span

    category_link = category_link_span.parent['href']
    journals_doc = CachedWebPage.get_cached_doc(:url => join_url("#{category_link}/titles?resultsPerPage=100"), :grep => "wiley")
    journals_links = journals_doc.search("ol#titles > li > div.title > div.details > a")

    jtitle = raze(article.journal.title)
    jtitle = "journal of paediatrics and child health" if jtitle == "australian paediatric journal"

    journals_links.each do |link|
      return link['href'] if jtitle == raze(link.render_to_plain_text)
    end

    max_diff = 10
    match = nil

    journals_links.each do |link|
      title = raze(link.render_to_plain_text)
      diff = String.diff_string(jtitle, title)

      if diff < max_diff
        max_diff = diff
        match = link
      end
    end

    return match['href'] if match
    nil
  end

  def join_url(part = nil)
    basename = "http://onlinelibrary.wiley.com/"
    return basename unless part
    URI.parse(basename).merge(part).to_s
  end
end
