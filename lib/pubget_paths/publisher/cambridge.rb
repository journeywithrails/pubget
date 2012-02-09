class Publisher::Cambridge < Publisher::Base
  
  def issue_url(params= {})
    article = params[:article]
    key = "#{article.journal.base_url.split("=").last}"
    if key =~ /http/
      key = key.split("_").last
    end
    toc_url = nil
    
    if article.issue.blank? and !params[:inrequest]
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>article.journal.base_url, :details=>true)
       doc = parse_html(source)
       if doc.at("#available_volumes")
         doc.at("#available_volumes").search("a").each do |a|
            if a.render_to_plain_text =~ /First View Articles/i
               toc_url = "http://journals.cambridge.org/action/#{a['href']}"
            end
         end
       end
    else
       uissue = "#{article.issue.gsub(/[\D]/,'')}"
       toc_url = "http://journals.cambridge.org/action/displayIssue?jid=#{key}&volumeId=#{article.volume}&issueId=#{uissue.rjust(2, '0')}"
    end
    toc_url
  end
  
  def openurl(params={})
    article = params[:article]
    if article.get_url and article.get_url =~ /cambridge\.org/
      article.get_url
    elsif article.get_doi(params)
      "http://www.journals.cambridge.org/article_#{article.get_doi(params).split('/').last}"
    else
      "#{issue_url(params)}&spage=#{article.start_page}"
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    source = CachedWebPage.get_cached_url(issue_url(params), 1)
    doc = parse_html(source)
    path = nil
    
    doi = article.get_doi
    
    if doi 
      url = "http://dx.doi.org/#{doi}"

      cached_text, redirect_url = CachedWebPage.get_cached_url(:url=>url, :details=>true)

      adoc = Nokogiri::HTML.parse(cached_text)
      if node = adoc.at("a[text()*='PDF']")
        path = "http://journals.cambridge.org/action/#{node['href']}".strip
      end
    end
    
    unless path
      lowest = 10 #get at least 10 but get the lowest
      term2 = article.title.downcase
      doc.search("tr").each do |tr|
        if tr.at("h3")
          term1 = tr.at("h3").render_to_plain_text.downcase
          diff = Text::Levenshtein.distance(term1, term2)
          if diff < lowest
            lowest = diff
            tr.search("a").each do |a|
               if a.render_to_plain_text =~ /Abstract/
                 if match = /aid=([\d]*)&/.match(a['onclick'])
                   aid = match[1].to_i
                   fid = aid + 8
                   path = "http://journals.cambridge.org/action/displayFulltext?type=1&fid=#{fid}&aid=#{aid}"
                 end
               end
            end
          end  
        end
      end
    end
    path
  end
end