class Publisher::RSP < Publisher::Highwire
  def issue_url(params={})
    article = params[:article]
    "#{article.journal.base_url}/content/#{article.volume}/#{article.issue}.toc"
  end
  
  def pdf_url(params={})
    article = params[:article]
    doc, redirect_url = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :details=>true, :grep=>'rsp')
    uri = URI.parse(redirect_url)
    lowest = 15 #get at least 15 but get the lowest
    path = nil
    link = nil
    doc.search("li.toc-cit").each do |li|
      if li.at("h4")
        term1 = li.at("h4").render_to_plain_text.downcase
        term2 = article.title.downcase
        diff = 1000
        begin
          diff = diff_string(term1, term2)
        rescue
          puts "#{__FILE__}:#{__LINE__}: #{$!}"
        end
        if diff < lowest
         lowest = diff
         li.search("a").each do |a|
           if a.inner_text =~ /PDF/
             path = "#{uri.merge(a['href'])}"
             path = path.gsub("+html","") if path =~ /html$/
           end
         end
        end
      end
    end
    
    unless path
      unless uri.host.blank?
        puts "Try via search on #{uri.host}"
        search_url = uri.merge("/search?submit=yes&pubdate_year=#{article.article_date.year}&volume=&firstpage=&doi=&author1=&author2=&title=#{CGI.escape(article.title)}&tocsectionid=all&format=standard&hits=10&sortspec=relevance&submit=yes&submit=Submit").to_s
        doc, redirect_url = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon], :url=>search_url, :details=>true, :grep=>'rsc')
        if ft_link = doc.at("a[text()='Full Text (PDF)']")
          path = uri.merge(ft_link['href'].split('?').first).to_s
          path = path.gsub("+html","") if path =~ /html$/
        end
      end
    end
    
    unless path
      puts "Try via DOI"
      if article.get_doi.blank?
        # Nothing to do
      else
        path = get_pdf_from_abstract("http://dx.doi.org/#{article.get_doi}")
      end
    end
    
    #could also try via pmid (http://rsif.royalsocietypublishing.org/lookup/pmid?view=long&pmid=20129954)
    unless path
      puts "Try via DOI"
      if article.repo.include?('pubmed')
        path = get_pdf_from_abstract("http://rsif.royalsocietypublishing.org/lookup/pmid?view=long&pmid=#{article.pmid}")
      end
    end
    path
  end
  
  def get_pdf_from_abstract(url)
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true, :expires_in=>2.days)
    uri = URI.parse(redirect_url)
    meta_tag = doc ? doc.at("meta[@name='citation_pdf_url']") : nil
    if meta_tag
      if doc.to_s =~ /accepted manuscript/i
        if meta_tag['citation_pdf_url'].blank?
          article.manuscript_pdf_url = meta_tag['content'].gsub(/\+html$/, "")
        else 
          article.manuscript_pdf_url = meta_tag['citation_pdf_url']
        end
        return nil
      else
        return meta_tag['content'].gsub(/\+html$/, "")
      end
    else
      links = doc.search("a[text()*='Full Text (PDF)']")
      links.each do |link|
        puts link
        return uri.merge(link['href']).to_s.gsub(/\+html$/, "")
      end
    end
  end
end