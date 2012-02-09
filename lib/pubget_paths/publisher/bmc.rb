class Publisher::BMC < Publisher::Base
  
  def info
    
    csv = CSV.parse(CachedWebPage.get_cached_url(:url=>"http://www.biomedcentral.com/info/journals/biomedcentraljournallist.txt"))
    count = 0
    csv.each do |row|
      #["Publisher", "Journal name", "Abbreviation", "ISSN", "URL", "Start Date"]
      count += 1
      unless row[0] == "Publisher"
      
        title = row[1]
        title_abbreviation = row[2]
        issn = row[3]
        base_url = row[4]
        puts row.inspect
        update_journal("BMC", nil, issn,
          nil, title, title_abbreviation, base_url, nil, count, false)
      end
    end
  end

  def issue_url(params= {})
    article = params[:article]
    key = /^http:\/\/www\.([^\.].*)\.com/.match(article.journal.journal_host)
    key = /^http:\/\/([^\.].*)\.com/.match(article.journal.journal_host) unless key
    if key and key[1] =~ /ccforum/
      "#{article.journal.journal_host}/currentissue/browse.asp?volume=#{article.volume}&issue=#{article.issue}"
    else
      "#{article.journal.base_url}/articles/browse.asp?date=#{article.article_date.month}-#{article.article_date.year}"
    end
  end
  
  def openurl(params={})
    article = params[:article]
    if article.get_doi(params)
      key = article.get_doi.split("/").last 
      "http://www.biomedcentral.com/content/pdf/#{key}.pdf"
    else
      nil
    end
  end

  def pdf_url(params={})
    article = params[:article]
    if article.get_doi
      key = article.get_doi.split("/").last 
      "http://www.biomedcentral.com/content/pdf/#{key}.pdf"
    else
      # doc = CachedWebPage.get_cached_doc(:url=>issue(article))
      nil
    end
  end

end