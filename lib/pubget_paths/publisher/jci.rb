class Publisher::JCI < Publisher::Base
  
  def issue_url(params)
    article = params[:article]
    if article.issue.blank?
      "http://www.jci.org/just-published"
    else
      "http://www.jci.org/#{article.volume}/#{article.issue}"
    end
  end
  
  def openurl(params)
    article = params[:article]
    issue = issue(article)
    return issue.blank?  ? "http://www.jci.org/just-published" : "http://www.jci.org/#{article.volume}/#{issue}"
  end

  def pdf_url(params={})
    article = params[:article]
    return nil if (article.get_doi.blank? and article.issue.blank?)
    p, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://dx.doi.org/#{article.get_doi}", :details=>true, :expires_in=>2.days)
    
    if docidmatch = /www\.jci\.org\/articles\/view\/([0-9]+)$/.match(redirect_url)
      return "http://www.jci.org/articles/view/#{docidmatch[1]}/files/pdf"
    elsif not article.issue.blank?
      iss_doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue(article), :details=>true)
      lowest = 15
      a = nil
      ft = nil
      iss_doc.search("div.Article").each do |adiv|
        term1 = adiv.at("b").render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          puts "Found possible title match #{diff}"
          lowest = diff
          a = nil
          ft = nil
          adiv.search('a').each do |try_a|
            a = try_a if try_a.inner_text =~ /PDF/i
            ft = try_a if try_a.inner_text =~ /Full text/i              
          end
        end
      end
      if a
        if docidmatch = /articles\/view\/([0-9]+)\/pdf/.match(a['href'])
          return "http://www.jci.org/articles/view/#{docidmatch[1]}/files/pdf"
        end
      elsif ft
        if docidmatch = /articles\/view\/([0-9]+)/.match(ft['href'].to_s)
          return "http://www.jci.org/articles/view/#{docidmatch[1]}/files/pdf"
        end
      end
    end
    
    #Try PMC if all else fails
    pubmed_central_path
  end
end
  