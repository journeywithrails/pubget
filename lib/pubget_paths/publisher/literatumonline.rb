class Publisher::Literatumonline < Publisher::Base
  
  def pdf_url(params={})
    article = params[:article]
    doi = get_doi(article)
    if doi
      abs_doc, redirect_url = CachedWebPage.get_cached_url(:url=>"http://dx.doi.org/#{doi}", :details=>true, :expires_in=>2.days)
      uri = URI.parse(redirect_url)
      return "http://#{uri.host}/doi/pdf/#{doi}"
    end
    params[:use_pigeon] ||= false
    path = nil
    issue_url = issue(article)
    doc, redirected_url = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon], :url=>issue_url, :grep=>'future_medicine', :details=>true)
    uri = URI.parse(redirect_url)
    lowest = 10 #get at least 10 but get the lowest
    term2 = article.title.downcase
    doc.search("table").each do |table|
   
      if table.at("div.art_title")
        term1 = table.at("div.art_title").render_to_plain_text.downcase
        term1 = @@ic.iconv(term1)
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          table.search("a").each do |a|
            path = uri.merge(a['href']).to_s if a.render_to_plain_text =~ /PDF/
          end
        end
      end
    end
    path
  end
  
end