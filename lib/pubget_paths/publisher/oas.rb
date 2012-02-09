class Publisher::OAS < Publisher::Base

  def issue_url(params= {})
    article = params[:article]
    "#{article.journal.journal_host}/issue.cfm?volume=#{article.volume}&issue=#{article.issue}"
  end

   def pdf_url(params={})  
      article = params[:article]      
      params[:use_pigeon] ||= false
      path = nil
      source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'aos', :slp=>1)
      doc = parse_html(source)
      lowest = 10 #get at least 10 but get the lowest
      term2 = article.title.downcase
      doc.search("p strong a").each do |a|
         term1 = a.render_to_plain_text.downcase
         diff = diff_string(term1, term2)
         if diff < lowest
            lowest = diff
            adoc = parse_html(CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>"#{article.journal.journal_host}/#{a['href']}", :grep=>'oas'))
            adoc.search("p span.abstract_text a").each do |link|
               path = "#{article.journal.journal_host}/#{link['href']}" if link.inner_text =~ /PDF/
            end
         end
      end
      unless path
      
      base_url = /<h1><a href="([^"]*)">/.match(source)[1]
      ajax_path = /(articlelist.cfm\?sort=toc\&jrnid=[\d]+\&volid=[\d]+\&issid=[\d]+)/.match(source)[1]
      
      toc_url = "#{base_url}#{ajax_path}"
    
      source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>toc_url, :slp=>1, :grep=>'oas')
      doc = parse_html(source)
      
      doc.search("div#section-article_info").each do |div|
         p = div.at("p.article-title")
         if p
            term1 = p.render_to_plain_text.downcase
            diff = diff_string(term1, term2)
            if diff < lowest
               lowest = diff
               a = div.at("li.article-link-full_text a")
               path = "#{URI.parse(toc_url).merge(a['href'])}" if a
            end
         end
      end
    end
    path
  end
end
  