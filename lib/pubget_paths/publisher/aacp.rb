class Publisher::Aacp < Publisher::Base
  

  def relative_link origin_page_url, link
      origin_page_url = origin_page_url.gsub(' ','%20')
      if !link.match(/^http/)
           p = URI.parse(origin_page_url)
           if !link.match(/^\//)
             link = "/#{link}"
           end
           link = "#{p.scheme}://#{p.host}#{link}"
      end
      link
  end
  
  def dputs s
    puts s if $DEBUG
  end
  
  def pdf_url(params={})
    
    dputs "aacp::pdf_url"
    search_article = params[:article]
    dputs "Arcticle title: #{search_article.title}"
    pdf_url = nil
    lowest_diff = 10
    
    issn = search_article.issn.first.to_s.gsub("-","")
    journalUrl = "http://www.portico.org/Portico/browse/access/vols.por?journalId=ISSN_#{issn}"
    dputs "Journal: #{journalUrl}"
    journal_page = CachedWebPage::get_cached_doc journalUrl

    springerlink_url = (journal_page.search("a[@href*='springerlink.com']").first.attr("href") rescue nil)
    
    #search in sprigner if there is link on journal page
    
    if springerlink_url
      dputs "searching springerlink: #{springerlink_url}"
      agent = WWW::Mechanize.new
      agent.get(springerlink_url)
      form = agent.page.form_with(:name=>'aspnetForm')
      form.field_with(:name=>form.fields[1].name).value = search_article.title
      form.submit
      parse = Nokogiri::HTML(agent.page.content)
      parse.search("p.title").each do |search_result|
        found_article_title = search_result.text
        dputs "Article: #{found_article_title}"
        diff = diff_string(search_article.title.downcase, found_article_title.downcase, lowest_diff)
        if diff<lowest_diff
          found_pdf = relative_link springerlink_url, (search_result.parent.search("ul.resources.fulltextResources > li.pdf > a").attr("href").to_s rescue nil)
          if found_pdf
            lowest_diff = diff
            pdf_url = found_pdf
          end
        end        
      end
    end
    
    pastIssues_url = (journal_page.css("a[@href*='Pastissues.asp']").first.attr("href") rescue nil)
    
    
    #searching in past issues
    if pastIssues_url #https://www.aacp.com/Pastissues.asp
      dputs "searching in pastissues"
      magazineList = CachedWebPage::get_cached_doc  pastIssues_url
      
      #https://www.aacp.com/Pastissue_toc.asp?FID=799&issue=May%202011&folder_description=May%202011%20(Vol.%2023,%20No.%202)
      magazineList.css("a.article-link").each do |magazine|
         magazine_link = relative_link pastIssues_url, magazine.attr("href")
         
         magazine = CachedWebPage::get_cached_doc magazine_link
         #search articles
         magazine.css("table >tr:eq(1) >td >span:eq(1)").each do |span|
           dputs "Article: #{span.text}"
           diff = diff_string(search_article.title.downcase, span.text.downcase, lowest_diff)
           if diff < lowest_diff
             lowest_diff = diff
             dputs "==== FOUND ==="
             article_url = span.xpath("..").first.search("a[@href*='Pages']").attr("href").to_s
             article_url = relative_link magazine_link, article_url
             dputs "article_url #{article_url}"
             article = CachedWebPage::get_cached_doc  article_url
             pdf_url = (article.search("a[@href*='pdf']").first[:href] rescue nil)
             pdf_url = (relative_link article_url, pdf_url) if pdf_url
             pdf_url = article_url if !pdf_url #ask to login
           end
         end
      end
    end
    
    #searching on page itself
    issues = journal_page.css("a[@href*='&issue']")
   
    issues.each do |issue|
      issue_url = "http://www.portico.org#{issue[:href]}"
      dputs "issue_url: #{issue_url}" 
      issue_content = CachedWebPage::get_cached_doc  issue_url
      article_divs = issue_content.css(".options li")
      article_divs.each do |div|
        article_title = div.css(".titleline").text
        dputs "Article: #{article_title}"
        diff = diff_string(search_article.title.downcase, article_title.downcase,lowest_diff)
        if diff<lowest_diff
          pdf_url = div.css(".downloadLinks a").first.attr("href")
          pdf_url = "http://www.portico.org#{pdf_url}"
        end
      end
    end
    
    pdf_url
    
    #"http://www.portico.org/Portico/article/access/DownloadPDF.por?journalId=ISSN_10401237&issueId=ISSN_10401237v20i2&articleId=pf1m9kpzj3&fileType=pdf&fileValid=true"
  end
end  