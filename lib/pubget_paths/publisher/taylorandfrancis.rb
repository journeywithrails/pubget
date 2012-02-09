class Publisher::Taylorandfrancis < Publisher::Atypon
  
  def info
    #http://www.tandfonline.com/action/contentHoldings?code=TFCCA_2011
    source, redirect_url = CachedWebPage.get_cached_url(:url=>"http://www.tandfonline.com/action/contentHoldings?code=TFCCA_2011", :details=>true, :expires_in=>1.month)

    tsv = TSV.parse(source)
    
    #[ 0 - publication_title, 1 -	print_identifier, 2 -	online_identifier, 3 - date_first_issue_online	
    #  4 - num_first_vol_online, 5 -	num_first_issue_online, 6 -	date_last_issue_online, 7 -	num_last_vol_online	
    # 8 - num_last_issue_online, 9 -	title_url, 10 -	first_author, 11 -	title_ID	
    # 12 - embargo_info, 13 -	coverage_depth, 14 -	coverage_notes, 15 -	publisher_name ]
    
    count = 0
    tsv.each do |row|
      pissn = row[1]
      eissn = row[2]
      title = row[0]
      base_url = row[9]
      count = count + 1
      update_journal("Informaworld", nil, pissn, eissn, title, nil, base_url, nil, count)
    end
    
  end
  
  def openurl(params)
    article = params[:article]
    doi = article.get_doi(params)
    return  doi  ? "http://www.tandfonline.com/doi/abs/#{doi}" : nil
  end

  def pdf_url(params={})
    article = params[:article]
    
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
    
    lowest = 10 #get at least 10 but get the lowest
    path = nil
    doc.search("table.articleEntry").each do |table|
      unless table.render_to_plain_text.blank?
        if table.at("div.art_title")
          term1 = table.at("div.art_title").render_to_plain_text.downcase
          term2 = article.title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            a = table.at("a.pdfLink")
            doi =  a['href'].gsub("/doi/pdfplus/","")
            if a.render_to_plain_text =~ /PDF/
               uri = URI.parse(issue_url(params))
               path = "#{uri.merge(a['href'])}"
            end
          end
        end  
      end
    end
    
    unless path
       path = "http://www.tandfonline.com/doi/pdf/#{article.get_doi}"
    end
    path
  end
  
  def issue_url(params)
    article = params[:article]
    if (article.article_date.year > 1998)
      "#{article.journal.base_url.gsub('.com/', '.com/toc/')}/#{article.volume}/#{article.issue}"
    else
      article.journal.base_url
    end
  end
  
end