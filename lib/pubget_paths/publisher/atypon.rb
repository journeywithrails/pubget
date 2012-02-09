class Publisher::Atypon < Publisher::Base

  def info
    
    ('A'..'Z').each do |letter|
      #puts letter
      doc = CachedWebPage.get_cached_doc(:url=>"http://www.atypon-link.com/action/showJournals?browseType=title&alpha=#{letter}")

      doc.search("a.browse_link").each do |a|
        base_url = "http://www.atypon-link.com#{a['href']}"
        issue_doc = CachedWebPage.get_cached_doc(:url=>base_url)
        if issue_doc.at("table.content") and issue_doc.at("h1.journalTitle")
          issn = nil
          # Match with " " which is actuall ASCII 194
          if issn_match = /Print\s+ISSN: ([0-9]{4}-[0-9]{3}[0-9Xx])/.match(issue_doc.at("table.content").inner_text)
            issn = issn_match[1]
          end
          eissn = nil
          if eissn_match = /Electronic\s+ISSN: ([0-9]{4}-[0-9]{3}[0-9Xx])/.match(issue_doc.at("table.content").inner_text)
            eissn = eissn_match[1]
          end
          title = issue_doc.at("h1.journalTitle").inner_text
        
          #puts [title,issn,eissn,base_url].inspect
          update_journal("Atypon", nil, issn, eissn, title, nil, base_url, false, nil)
          
        end
      end
    end
  end
  
  def issue_url(params= {})
    article = params[:article]
    if article.volume != ""
      "#{article.journal.base_url.gsub('current','')}#{article.article_date.year}/#{article.volume}/#{article.issue}"
    else
      "#{articlejournal.base_url.gsub('current','')}0/0"
    end
  end
  
  def openurl(params)
    article = params[:article]
    if doi = article.get_doi(params)
      return "#{article.journal.journal_host}/doi/abs/#{doi}"
    end
    nil
  end
  
  def pdf_url(params={})
    article = params[:article]
    if doi = article.get_doi(params)
      return "#{article.journal.journal_host}/doi/pdf/#{doi}"
    end
    nil
  end
  
end