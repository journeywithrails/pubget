class Publisher::Liebert < Publisher::Atypon
  #http://www.liebertpub.com/urls/
  
  def issue_url(params)
    article = params[:article]
    if (article.article_date.year > 1998)
      "#{article.journal.base_url.gsub('.com/', '.com/toc/')}/#{article.volume}/#{article.issue}"
    else
      article.journal.base_url
    end
  end
  
   def openurl(params)
     article = params[:article]
     doi = article.get_doi(params)
     return  doi  ? "http://www.liebertonline.com/doi/abs/#{doi}" : nil
   end

  def pdf_url(params={})
    article = params[:article]
    path = nil
    if article.doi!=nil
      path = "http://www.liebertonline.com/doi/pdf/#{article.doi}"
    else
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
      lowest = 10 #get at least 10 but get the lowest
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
    end
    path
  end
  
end