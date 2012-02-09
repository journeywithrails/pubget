class Publisher::AnnualReviews < Publisher::Base
  
  def info
    
    #ftp://armeta:mor2get@arftp.annualreviews.org and get series file
    Net::FTP.open('arftp.annualreviews.org','armeta','mor2get') do |ftp|
       puts "connected to annualreviews - downloading file"
       ftp.getbinaryfile("/ar_series.xml", "#{PUBLIC_BASE}/ar_series.xml", 1024)
    end
    
    file_name = "#{PUBLIC_BASE}/ar_series.xml"
    #file_name = download_ar_series
    doc = XML::Document.file(file_name)
    count = 0
    doc.find("journal").each do |journal|
      pissn = nil
      eissn = nil
      journal.find('issn').each do |issn|
        pissn = issn.content unless pissn
        eissn = issn.content 
      end
      base_url = journal.find_first('journal_homepage').content
      title = journal.find_first('title').content
      count += 1
      journal = Journal.find_by_issn(pissn)
      unless journal
        update_journal("Annual Reviews", nil, pissn,
          eissn, title, nil, base_url, true, count, false)
      end
      if eissn
        ejournal = Journal.find_by_issn(eissn)
        unless ejournal
          update_journal("Annual Reviews", nil, pissn,
            eissn, title, nil, base_url, true, count, false)
        end
      end
    end
  end

  def openurl(params={})
    article = params[:article]
    if article.get_doi(params.merge(:article=>article))
      path= "#{article.journal.journal_host}/doi/full/#{article.get_doi(params.merge(:article=>article))}"
    else
      issue_url article
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    path = nil
    if get_doi(params.merge(:article=>article))
      path = "#{article.journal.journal_host}/doi/pdf/#{get_doi(article)}"
    end
    unless path
      source = CachedWebPage.get_cached_url(:url=>issue_url(params), :slp=>1, :grep=>"annual_reviews")
      doc = parse_html(source)
      lowest = 10 #get at least 10 but get the lowest
      doc.search("//div[@class='articleBoxMeta']/h2/a").each do |a|
      #doc.search("table").each do |tbody|
        term1 = a.content.downcase
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          pdf_a = a.parent.parent.parent.search("div[@class='articleLinksIcons']/ul/li[@class='pdf']/a").first
          if pdf_a.render_to_plain_text =~ /PDF/
            path = "http://arjournals.annualreviews.org" + pdf_a.attr('href')
          end
        end
      end
    end
    path
  end

  def issue_url(params= {})
    article = params[:article]
    key = "#{article.journal.base_url.split("?").first.split('/').last}"
    volume = article.volume
    issue = issue.blank? ? 1 : issue
    "http://arjournals.annualreviews.org/toc/#{key}/#{volume}/#{issue}"
  end

end
