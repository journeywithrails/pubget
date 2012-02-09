class Publisher::Mayo < Publisher::Base

  def issue_url(params={})
    article = params[:article]
    "#{article.journal.base_url}/content/#{article.volume}/#{article.issue}"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
     doc = parse_html(CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'mayo'))
      lowest = 10 #get at least 10 but get the lowest
      path = nil
      doc.search("li.cit").each do |li|
        if li.at("h4")
          term1 = li.at("h4").render_to_plain_text.downcase
          term2 = article.title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            li.search("a").each do |a|
              path = "http://www.mayoclinicproceedings.com#{a['href'].gsub('+html','')}" if a.render_to_plain_text =~ /PDF/
            end
          end
        end
      end
      path
  end
end