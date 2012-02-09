class Publisher::Bioscience < Publisher::Base
  
  def issue_url(params= {})
    article = params[:article]
    "http://www.bioscience.org/current/vol#{article.volume}.htm"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    doc = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'bioscience')
    lowest = 10 #get at least 10 but get the lowest
    path = nil
    doc.search("p").each do |p|
      a = p.at("a")
      if a
        term1 = a.render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
         lowest = diff
         p.search("a").each do |a|
            if a.render_to_plain_text =~ /PDF Type II/i
               uri = URI.parse(issue_url(params))
               path = uri.merge(a['href']).to_s
               break
            end
         end
        end  
       end
     end
     path
  end
end