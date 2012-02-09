class Publisher::Informahealthcare < Publisher::Atypon
  
  def info
  
    url = "http://informahealthcare.com/userimages/ContentEditor/1263501535019/Informa_Healthcare_holdings_1_7_10.xls"
  
    # source = ""
    #       Net::SSH.start("10.0.16.188", "pubget", :password => "kerw00d") do |session|
    #         session.exec!('rm /tmp/Informa_Healthcare_holdings_1_7_10.xls')
    #         session.exec!('cd /tmp;wget "http://informahealthcare.com/userimages/ContentEditor/1263501535019/Informa_Healthcare_holdings_1_7_10.xls"')
    #         source = session.exec!('xls2csv /tmp/Informa_Healthcare_holdings_1_7_10.xls').sub(/\s+$/, "\n") 
    #       end
    csv = FasterCSV.flexible_import("http://informahealthcare.com/userimages/ContentEditor/1263501535019/Informa_Healthcare_holdings_1_7_10.xls")
    
    count = 0
    csv.each do |row|
      #0Publication	1Print ISSN	2Online ISSN	3URL	4First Online Issue	5Last Online Issue     
      if row.size > 3
        pissn = (row[1] =~ /\d\d\d\d\-\d\d\d[Xx\d]/) ?  row[1].gsub(/[^\d\-xX]/,'') : nil
        eissn = (row[2] =~ /\d\d\d\d\-\d\d\d[Xx\d]/) ?  row[2].gsub(/[^\d\-xX]/,'') : nil
        if pissn or eissn
          title = row[0].titleize
          base_url = row[3]
          count += 1
          update_journal("Informaworld", nil, pissn, eissn, title, nil, base_url,
            nil, count)
          update_source("Informahealthcare", nil, pissn, eissn, title, nil, base_url,
            nil, count)
        end
      end
    end
      
  end
  
  def issue_url(params)
    article = params[:article]
    if (article.article_date.year > 1998)
      "http://#{URI.parse(article.journal.base_url).host}/toc/gas/#{article.volume}/#{article.issue}"
    else
      article.journal.base_url
    end
  end
  
  def openurl(params={})
    article = params[:article]
    if article.get_doi(params)
      "http://informahealthcare.com/doi/abs/#{article.get_doi(params)}"
    else
      nil
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    path = nil
    if article.doi != nil
      path = "http://informahealthcare.com/doi/pdf/#{article.doi}"
    elsif article.get_doi != nil
      path = "http://informahealthcare.com/doi/pdf/#{article.get_doi}"
    else
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true, :expire_in => 1.week)
      lowest = 10 #get at least 10 but get the lowest
      doc.search('div.publication_entry > div.publication_content').each do |result|
        next if result.text.blank?
        
        if result.at("div.title")
          term1 = article.title.downcase
          term2 = result.at("div.title").text.downcase
          diff = String.diff_string(term1, term2)
          
          if diff < lowest
            lowest = diff
            link = result.at("div.article_types > a[text()='Full Text']")

            if link
              host = URI.parse(article.journal.base_url).host
              href = link['href'].gsub('/doi/full/', '/doi/pdf/')
              path = "http://#{host}#{href}"
            end
          end
        end
      end
    end
    path
  end
end
