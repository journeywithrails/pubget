class Publisher::Saudi < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    if volume.to_i > 24
        "http://saudiannals.net/previous_issues/v#{article.volume}i#{article.issue}.html"
     else
        if article.issue =~ /-/
           "http://app.kfshrc.edu.sa/annals/Articles_list.asp?s_Article_Volume=#{article.volume}&s_Article_Issue=#{article.issue.split('-').first}"
        else
           "http://app.kfshrc.edu.sa/annals/Articles_list.asp?s_Article_Volume=#{article.volume}&s_Article_Issue=#{article.issue}"
        end
     end
  end
  
  def pdf_url(params={})
    article = params[:article]
    path = nil
    source = get_cached_url(:url=>issue_url(params))
    if volume.to_i <= 24
      begin
         pg2 = get_cached_url(:url=>"#{issue_url(params)}&ArticlesPage=2")
         source = source + pg2
         pg3 = get_cached_url(:url=>"#{issue_url(params)}&ArticlesPage=3")
         source = source + pg3
      rescue
      end
      doc = parse_html(source)

      lowest = 10 #get at least 10 but get the lowest
       term2 = article.title.downcase
       doc.search("table tr").each do |table|

         table.search("td").each do |td|
           term1 = td.render_to_plain_text.downcase
           term1 = @@ic.iconv(term1)
           diff = diff_string(term1, term2)
           if diff < lowest
             lowest = diff
             table.search("a").each do |a|
               path = a['href'] if a['href'] =~ /pdf$/i
             end
           end
         end
       end
    else
       doc = parse_html(source)
       lowest = 10 #get at least 10 but get the lowest
       term2 = article.title.downcase
       doc.search("a").each do |a|
           term1 = a.render_to_plain_text.downcase.gsub(". PDF", "")
           term1 = @@ic.iconv(term1)
           diff = diff_string(term1, term2)
           if diff < lowest
             lowest = diff
             path = a['href'] if a['href'] =~ /pdf$/i
           end
       end
    end
    path
  end
end