class Publisher::Highwire < Publisher::Base
  
  def info

    csv = FasterCSV.flexible_import("http://highwire.stanford.edu/librarians/AtoZList.xls")
    count = 0
    actions = {:added=>0, :updated=>0, :total=>0}
    
    pubs = []
    domains = []
    csv.each do |row|
      #0"Journal Name (updated 15 March 2010)",1"Who is the publisher?",2"Main URL for the journal site?",3"Online ISSN number?",4"Print ISSN number?",
      #5"What is the range of content online?",6"Are there free back issues?",7"Is this a free site?",8"Start-Date of Full  Text",9"End-Date of Full Text"
      next unless row[1]
      title = row[0]
      unless title =~ /Journal Title/
        publisher_detail = row[1].strip
        publisher = "Highwire"
        base_url = row[2].strip
        if base_url 
          domains << URI.parse(base_url).host
        end
        pubs << publisher_detail unless publisher_detail =~ /elsevier/i
        eissn = (row[3] =~ /\d\d\d\d-\d\d\d[\dXx]/) ? row[3].strip : nil
        pissn = (row[4] =~ /\d\d\d\d-\d\d\d[\dXx]/) ? row[4].strip : nil
        
        free_back = nil
        if free_match = /Yes: after ([\d]{1,2}) months/.match(row[6])
          free_back = free_match[1].to_i
        elsif free_match = /Yes: after ([\d]{1,2}) years/.match(row[6])
          free_back = free_match[1].to_i * 12
        elsif free_match = /Yes:/.match(row[6])
          puts "Bad free #{free_match}"
        end
        if free_all_match = /Yes/.match(row[7])
          free_back = 0
        end
        pdf_start= nil
        pdf_end = nil
        unless row[9] =~ /current/
          pdf_end = Date.date_from_string(row[9])
        end
        if row[8] =~ /\d{5}/
          pdf_start = Date.date_from_string("1900-Jan-0") + row[8].to_i
          if pdf_start.year > 1900
            pdf_start = pdf_start - 1
          end
          if pdf_start.year > 2000
            pdf_start = pdf_start - 1
          end
        end
        count += 1
         if pdf_end.blank?
           action = update_journal("Highwire", nil, pissn, eissn, title, nil, base_url, true, count, uncertain_title=true,
             nil, pdf_start, pdf_end, secondary_source=false, certain_date=true)
         else
           action = update_source("Highwire", nil, pissn, eissn, title, nil, base_url, true, count, uncertain_title=true,
             nil, pdf_start, pdf_end, secondary_source=true, certain_date=true)
         end
         actions[:total] += 1
         if action == "added"
           actions[:added] += 1
         elsif action == "updated"
           actions[:updated] += 1
         end
      end
    end
    
    f1 = File.open("db/highwire-pubs.txt","w")
    pubs.sort.uniq.each do |pub|
      f1.puts pub
    end
    f1.close
    
    f2 = File.open("db/highwire-domains.txt","w")
    domains.sort.uniq.each do |domain|
      f2.puts domain
    end
    f2.close
    #`git commit db/highwire-pubs.txt -m='update highwire'`
    #`git commit db/highwire-domains.txt -m='update highwire'`
    #`git push`
    CheckMonitor.checked("lister_info::highwire", 1.months, "Updated lister for Highwire", actions[:updated], actions[:added], actions[:total])
    
    
  end

  def openurl(params={})
    article = params[:article]
    transform = params[:transform]
    if article.exists_on_pubmed
      uri = URI.parse(article.journal.base_url)
      uri.merge("/cgi/pmidlookup?view=long&pmid=#{article.pmid}").to_s
    elsif article.first_author.blank?
      "http://highwire.stanford.edu/cgi/searchresults?sendit=Search&pubdate_year=#{article.year}&volume=#{article.volume}&title=#{article.title.gsub(' ','+')}&firstpage=#{article.start_page}&andorexacttitle=phrase"
    else
      "http://highwire.stanford.edu/cgi/searchresults?sendit=Search&pubdate_year=#{article.year}&volume=#{article.volume}&author1=#{article.first_author[0].split(' ').last}&title=#{article.title.gsub(' ','+')}&firstpage=#{article.start_page}&andorexacttitle=phrase"
    end
  end

  def pdf_url(params={ })
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    toc_url = issue_url(params)

    if toc_url.blank?
      puts "TOC blank - try by doi #{article.get_doi}"
      #TODO
      path = find_pdf_url_by_doi(params) ###
      if path.blank? and not article.manuscript_pdf_url.blank? ###
        return nil
      end
    else
      puts "Found issue url #{toc_url}"
    end

    source = nil
    if path.blank? and (not toc_url.blank?)
      source, redirect_url = CachedWebPage.get_cached_url(:url=>toc_url, :grep=>'highwire', :details=>true)
    elsif path.blank? and toc_url.blank? and article.article_date and article.journal.base_url
      puts "Working with blank issue, so searching by year..."
      source = ""
      #TODO
      year_url = archive_url(params)

      unless (article.article_date.year == Date.today.year) and
        (article.journal.base_url =~ /www\.bmj\.com/)
        puts "Getting contents for year from #{year_url}"
        year_source, redirect_url = CachedWebPage.get_cached_url(:url=>year_url, :details=>true, :grep=>'highwire')
        doc = parse_html(year_source)
        doc.search("a").each do |a|
          is_issue_link =
            (article.issue =~ /Suppl/ && a.render_to_plain_text =~ /suppl/i) ||
              (a['href'] =~ /content\/vol[0-9]+.?/)
          if is_issue_link
            issue_url = File.join(article.journal.base_url, a['href'])
            puts "Found issue url: #{issue_url}"
            source = source + CachedWebPage.get_cached_url(:url=>issue_url, :grep=>'highwire')
          end
        end
      end

      if article.journal.base_url =~ /www\.bmj\.com/
        url = File.join(article.journal.base_url, "cgi/pastseven?rangedays=7&hits=200")
        source = source + CachedWebPage.get_cached_url(:url=>url, :grep=>'highwire', :expired_in => 1.weeks)
      end
    end

    if source
      if article.journal.base_url =~ /www\.bmj\.com/
        bmj = Publisher::BMJ.new
        path = bmj.parse_source(source, article)
      else
        puts "parsing highwire issue pages"
        path = parse_source(source, article)
      end
    end

    if path.blank? && article.journal.base_url =~ /bmj.com/i && article.pmid !~ /pgtmp/
      begin
        pmid_url = File.join(article.journal.base_url,
          "cgi/pmidlookup?view=long&pmid=#{article.pmid}")
        puts pmid_url
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=>pmid_url, :grep=>'highwire', :details=>true)
        uri = URI.parse(redirect_url)
        meta_tag = doc.at("meta[@name='citation_pdf_url']")
        if meta_tag
          path = meta_tag['content']
        else
          abstract_url = nil
          if doc.at("a[text()='extract/abstract']")
            abstract_path = doc.at("a[text()='extract/abstract']")['href']
            abstract_url = "#{uri.merge(abstract_path)}"
          end
          if abstract_url
            doc, redirect_url = CachedWebPage.get_cached_doc(:url=>abstract_url, :details=>true, :grep=>'highwire')
            uri = URI.parse(redirect_url)
            doc.search("div#ArticleNav a").each do |a|
              if a.render_to_plain_text =~ /PDF/
                path = "#{uri.merge(a['href'])}"
                path += ".pdf" if path !~ /\.pdf$/
                break
              end
            end
          end
        end
      rescue
        puts "Could not find BMJ this way: #{$!}"
      end
    end

    if path.blank?
      path = find_pdf_url_by_doi(params)
    end

    if path.blank? and article.exists_on_pubmed
      begin
        path = find_pdf_url_by_pmid(params)
      rescue Exception
        puts "Have a PMID, but does not work: #{$!}"
      end
    end

    # if path.blank? and toc_url
    #
    #   Scraping.require_implementation(:Highwire)
    #   scraper = Scraping::ArticleScrapers::Highwire.new
    #   articles = scraper.get_article_values_from_index(toc_url)
    #   #puts "articles:"; articles.map {|a| puts "\n\n#{a.inspect}"}
    #   #path = find_pdf_url_from_title(articles)
    #   path = find_pdf_url_from_article_hashes(articles, article)
    # end

    return path
  end

  def find_pdf_url_by_doi(params={ })
    article = params[:article]
    params[:use_pigeon] ||= false
    puts "*** Trying by DOI: #{article.get_doi} ***"
    if article.get_doi.blank?
      return nil
    else
      #source = get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>"http://dx.doi.org/#{article.get_doi}", :slp=>1, :grep=>'highwire')
      #doc = parse_html(source)
      doc = nil
      redirect_url = nil
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://dx.doi.org/#{article.get_doi}", :details=>true, :expires_in=>2.days)
      uri = URI.parse(redirect_url)
      if doc.at("title").inner_text =~ /DOI Not Found/
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"#{article.journal.journal_host}/cgi/search?doi=#{article.get_doi}", :details=>true)
        uri = URI.parse(redirect_url)
        if (link = doc.at("a[text()='Abstract']")) or (link = doc.at("a[text()='Extract']"))
          doc, redirect_url = CachedWebPage.get_cached_doc(:url=>uri.merge(link['href']), :details=>true)
          uri = URI.parse(redirect_url)
        else
          doi_part = article.get_doi.split("/").last
          puts "Try DOI via journal instead"
          doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"#{article.journal.journal_host}/cgi/content/abstract/#{doi_part}", :details=>true)
          uri = URI.parse(redirect_url)
        end
      end
      meta_tag = doc ? doc.at("meta[@name='citation_pdf_url']") : nil
      if meta_tag
        if doc.to_s =~ /accepted manuscript/i
          if meta_tag['citation_pdf_url'].blank?
            article.manuscript_pdf_url = meta_tag['content'].gsub(/\+html$/, "")
          else
            article.manuscript_pdf_url = meta_tag['citation_pdf_url']
          end
          return nil
        else
          return meta_tag['content'].gsub(/\+html$/, "")
        end
      else
        links = doc.search("a[text()*='PDF of print issue']")
        if links.length == 1
          return uri.merge(links.first['href']).to_s
        else
          return nil
        end
      end
    end
  end

  def find_pdf_url_by_pmid(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    puts "*** Trying by PMID: #{article.pmid} ***"
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>openurl(params), :details=>true, :expires_in=>2.days)
    uri = URI.parse(redirect_url)
    meta_tag = doc ? doc.at("meta[@name='citation_pdf_url']") : nil
    if meta_tag
      if doc.to_s =~ /accepted manuscript/i
        if meta_tag['citation_pdf_url'].blank?
          article.manuscript_pdf_url = meta_tag['content'].gsub(/\+html$/, "")
        else
          article.manuscript_pdf_url = meta_tag['citation_pdf_url']
        end
        return nil
      else
        return meta_tag['content'].gsub(/\+html$/, "")
      end
    else
      links = doc.search("a[text()*='PDF of print issue']")
      if links.length == 1
        return uri.merge(links.first['href']).to_s
      else
        return nil
      end
    end
  end

  def issue_url(params= { })

    article = params[:article]
    hw_issue = article.issue
    if article.issue =~ /Pt \d+\-\d+/
      article.issue = hw_issue = article.issue.split.first.strip

    elsif article.issue =~ /\d+ Pt \d+/
      article.issue = hw_issue = article.issue.split.first.strip
    elsif article.issue =~ (/^(\d+)\-\d+$/)
      article.issue = hw_issue = article.issue.match(/^(\d+)\-\d+$/)[1]
    elsif article.issue =~ (/^(\d+)pt\.\d+$/i)
      article.issue = hw_issue = article.issue.match(/^(\d+)pt\.\d+$/i)[1]
    elsif article.issue =~ /Pt/i
      hw_issue = article.issue.split.last.strip
    end

    toc_url =
      if article.journal.base_url.blank?
        nil
      elsif hw_issue.blank?
        nil
      elsif article.volume =~ /Suppl/
        File.join(article.journal.base_url,
          "content/vol#{article.volume.split[0]}/suppl_#{article.volume.split.last}/")
      elsif article.issue =~ /^[0-9]+ Suppl$/i
        n = article.issue.match(/^[0-9]+/)[0]
        File.join(article.journal.base_url, "content/vol#{article.volume}/#{n}S_Suppl/")
        #elsif issue =~ /Suppl/
        #  "#{journal.base_url}/content/vol#{volume.split[0]}/suppl_1/"
      elsif match = article.issue.match(/^\d+ Suppl (\d+)$/i)
        article.issue = "suppl_#{match[1]}"
        File.join(article.journal.base_url, "content/vol#{article.volume}/#{article.issue}")
      elsif (not article.volume.blank?) && (not hw_issue.blank?)
        File.join(article.journal.base_url, "content/vol#{article.volume}/issue#{hw_issue}/")
      end
    #if issue.blank? && journal.base_url =~ /www.bmj.com/
    #  toc_url = File.join(journal.base_url, "cgi/pastseven?rangedays=7&hits=200")
    #end
    return toc_url
  end

  def parse_source(source, article)
    url = nil
    doc = parse_html(source)
    guesses = [
      "/cgi/reprint/#{article.volume}/#{article.issue}/#{article.start_page}.pdf",
      "/content/#{article.volume}/#{article.issue}/#{article.start_page}.full.pdf+html",
      "/content/#{article.volume}/#{article.issue}/#{article.first_page}.full.pdf+html",
      "/cgi/reprint/#{article.volume}/#{article.issue}/#{article.start_page}",
      "/cgi/content/full/#{article.volume}/#{article.issue}/#{article.start_page}",]

    guesses.each do |guess|
      a = doc.at("a[@href='#{guess}']")
      if a
        url = File.join(article.journal.base_url, guess)
        url.gsub!(/\+html$/, "")
        url.gsub!(/content\/full/, "reprint")
        url += ".pdf" if not url.match(/\.pdf$/)
      end
    end

    if url == nil
      puts "no guess worked; looking for page number"
      page_link = /a href="(.+?#{article.volume}\/\d+\/#{article.start_page})">/i
      source.scan(page_link).each do |s|
        t = s[0]
        a = doc.at("a[@href='#{t}']")
        if a and a.inner_html =~ /pdf/i
          url = File.join(article.journal.base_url, a['href'])
          url.gsub!(/\+html$/, "")
          url.gsub!(/content\/full/, "reprint")
          url += ".pdf" if not url.match(/\.pdf$/)
        end
      end
      if url == nil
        puts "couldn't find page number; searching by title"
        url = find_pdf(doc, "dl dt", article)
        url = find_pdf(doc, "dl dd", article) unless url
        url = find_pdf(doc, "li.cit", article) if url == nil
        url = find_pdf(doc, "//tr//td", article) if url == nil
      end
    end
    return url
  end

  def find_pdf(doc, article_selector, article)
    url = nil
    lowest = 15 # get at least 10 but get the lowest
    article_elems = doc.search(article_selector)
    article_elems.each do |article_elem|
      next if article_elem.render_to_plain_text.blank?

      title_elem = article_elem.at("h4")
      title_elem = article_elem.at("label") if title_elem == nil
      title_elem = article_elem.at("strong") if title_elem == nil
      next unless title_elem

      term1 = title_elem.render_to_plain_text.downcase
      term2 = article.title.downcase
      diff = diff_string(term1, term2)
      next if diff >= lowest

      puts "Found possible title match #{diff}"
      lowest = diff
      a, ft = nil
      dup = 0

      find_link = lambda do |target|
        target.search('a').each do |try_a|
          a = try_a and dup += 1 if try_a.inner_text =~ /full text pdf/i or try_a.inner_text =~ /PDF/i
          ft = try_a if try_a.inner_text =~ /Full text/i
        end
      end

      find_link.call(article_elem)
      a, ft = nil if dup > 1

      unless a
        next_sibling = article_elem.next_sibling
        next_sibling = article_elem.next_sibling.next_sibling if next_sibling.inner_text.blank? if next_sibling
        find_link.call(next_sibling) if next_sibling and a.blank?
      end

      a = article_elem.next_sibling.at("a[text()*='PDF']") if article_elem.next_sibling unless a
      a = article_elem.next_sibling.at("a[text()*='PDF »']") if article_elem.next_sibling unless a
      a = article_elem.at("a[text()*='[PDF]']") unless a
      a = article_elem.at("a[text()*='[Print PDF]']") unless a
      a = article_elem.at("a[text()*='Full Text (PDF)']") unless a

      unless a
        if a.blank? and article_elem.next_sibling
          article_elem.next_sibling.search('a').each do |ia|
            a = ia and break if ia.inner_text =~ /PDF/
          end
        end
      end

      unless a
        parent = title_elem
        while parent do
          find_link.call(parent) and break if parent.name == 'td'
          parent = parent.name == 'document' ? nil : parent.parent
        end
      end

      if a.blank? and not ft.blank?
        #http://www.bmj.com/cgi/section_pdf/339/nov10_1/b4432.pdf
        #http://www.bmj.com/cgi/content/full/339/nov10_1/b4432
        uri = issue_url(:article=>article) ?
          URI.parse(issue_url(:article=>article)) : URI.parse(article.journal.base_url)
        url = uri.merge(ft['href'].gsub('content/full', 'section_pdf')).to_s if uri.host =~ /bmj\.com/
      end

      if a
        uri = issue_url(:article=>article) ?
          URI.parse(issue_url(:article=>article)) : URI.parse(article.journal.base_url)
        url = uri.merge(a['href']).to_s
      end

      if url
        url.gsub!(/\+html.*$/, "")
        url += ".pdf" if not url.match(/\.pdf$/)
      end
    end
    return url
  end

  def archive_url(params={ })
    article = params[:article]
    base_url = article.journal.base_url
    return nil unless base_url

    year = article.article_date.year
    File.join(base_url, base_url.match(/www\.bmj\.com/) ?
      "archive/#{year}.dtl" : "contents-by-date.#{year}.shtml")
  end
end
