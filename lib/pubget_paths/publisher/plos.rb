class Publisher::Plos < Publisher::Base

  def issue_url(params={})
    article = params[:article]
    if article.journal.base_url =~ /perlserv/
      article.allen_press_issue_url
    else
      if article.volume and article.issue 
        vstring = "v#{article.volume.rjust(2,'0')}"
        istring = "i#{article.issue.rjust(2,'0')}"
        "#{article.journal.base_url.gsub('v01', vstring).gsub('i01',istring)}"
      else
        "#{article.journal.base_url}"
      end
    end
  end
  
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon],
                                          :url=>issue_url(params), :slp=> 1,
                                          :grep=>'plos')
    doc = parse_html(source)
    term2 = article.title.downcase
    
    if article.journal.base_url =~ /perlserv/
      path = find_path_for_perlserv(doc, term2, 10)
    else
      path = find_path_when_not_on_perlserv(doc, term2, 10)
    end

    if path.nil?
      doc, redirect_url = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon],
                                                       :url=>"http://dx.doi.org/#{article.get_doi(:force=>true)}",
                                                       :grep=>'plos', :expires_in=>2.days)
      if doc.at("title").to_s =~ /DOI Not Found/
        doc, redirect_url = CachedWebPage.get_cached_doc(:use_pigeon=>params[:use_pigeon],
                                                         :url=>"http://dx.plos.org/#{article.get_doi(:force=>true)}",
                                                         :grep=>'plos', :expires_in=>2.days)
      end
      path = find_path_in_amenu(doc, article)
    end
    path = find_path_in_list_item(doc, article) if path.nil?
    path
  end

  private

  def find_path_for_perlserv(doc, term2, lowest)
    path = nil
    doc.search("dt a").each do |a|
      term1 = a.render_to_plain_text.downcase.gsub('thumbnail','')
      diff = diff_string(term1, term2)
      if diff < lowest
        lowest = diff
        path = a['href'].gsub("get-document","get-pdf")
      end
    end
    path
  end

  def find_path_when_not_on_perlserv(doc, term2, lowest)
    path = nil
    doc.search("div.article a").each do |a|
      term1 = a.render_to_plain_text.downcase.gsub('thumbnail','')
      diff = diff_string(term1, term2)
      if diff < lowest
        lowest = diff
        key = a['href'].split(";").first.split("/").last
        #TODO: put these on assets or pmc as they are not inline
        path = "#{article.journal.journal_host}/article/fetchObjectAttachment.action?uri=#{key}&representation=PDF"
      end
    end
    path
  end

  def find_path_in_amenu(doc, article)
    path = nil
    amenu = doc.at("div#articleMenu")
    amenu = doc.at("div#sideNav") unless amenu
    if amenu
      amenu.search("a").each do |a|
        if a.render_to_plain_text =~ /PDF/            
          uri = URI.parse(article.journal.base_url)
          path = "#{uri.merge(a['href'])}"
        end
      end
    end
    path
  end

  def find_path_in_list_item(doc, article)
    path = nil     
    li = doc.at("li.download")
    if li
      li.search("a").each do |a|
        if a.render_to_plain_text =~ /PDF/            
          uri = URI.parse(article.journal.base_url)
          path = "#{uri.merge(a['href'])}"
        end
      end
    end
    path
  end
end
