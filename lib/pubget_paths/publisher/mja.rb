class Publisher::MJA < Publisher::Base

  def issue_url(params={})
    article = params[:article]
    if issue(article)
      "http://www.mja.com.au/public/issues/#{article.volume}_#{article.issue.rjust(2,'0')}_#{article.article_date.strftime('%d%m%y')}/contents_#{article.article_date.strftime('%d%m%y')}.html"
    else
      "http://www.mja.com.au/"
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    if article.article_date.year > 1995
       doc = parse_html(CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'mja'))
       lowest = 10 #get at least 10 but get the lowest
       term2 = article.title.downcase
       mja_issue_base = "http://www.mja.com.au/public/issues/#{article.volume}_#{article.issue.rjust(2,'0')}_#{article.article_date.strftime('%d%m%y')}/" if article.issue
       doc.search("table").each do |table|
      
         if table.at("b a")
           term1 = table.at("b a").render_to_plain_text.downcase
           term1 = @@ic.iconv(term1)
           diff = diff_string(term1, term2)
           if diff < lowest
             lowest = diff
             table.search("a").each do |a|
               path = "#{mja_issue_base}#{CGI.unescape(a['href'])}" if a.render_to_plain_text =~ /HTML/ unless path
               path = "#{mja_issue_base}#{CGI.unescape(a['href'])}" if a.render_to_plain_text =~ /PDF/
             end
           end
         end
       end
    end
    path
  end
  
end