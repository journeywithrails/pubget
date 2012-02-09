class Publisher::Cancerimmunity < Publisher::Base
  
  
  def info
    update_journal("Cancerimmunity", nil, nil, "1424-9634", "Cancer immunity : a journal of the Academy of Cancer Immunology", nil, "http://www.cancerimmunity.org/",
    nil, 1, uncertain_title=false)
    CheckMonitor.checked("lister_info::Cancerimmunity", 1.years, "Updated lister for MLA", 1,0,1)
  end
 
  def issue_url(params= {})
    article = params[:article]
    if article.volume.present?
      "http://www.cancerimmunity.org/v#{article.volume}/index.htm"
    else
      nil
    end
  end
  
  def pdf_url(params)
    article = params[:article]
    path = nil

    # try finding path by issue
    url = issue_url(params)
    doc, referer_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true)
    lowest = 15
    if doc
      #get volume of doc
      doc.search("b").each do |strong|
        if inner_text = strong.inner_text.split("(").first
          term1 = strong.inner_text.split("(").first.strip.downcase.gsub(/\s*\n\s*/," ")
          term2 = article.title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            puts "Found possible title match #{diff}"
            if (strong.parent.children) and (link = strong.parent.children.at("a[text()='PDF']"))
              uri = URI.parse(referer_url)
              path = uri.merge(link['href']).to_s
            end
          end
        end
      end
    end
   
    unless path
      # This was searching for the URL in linkouts from PubMed and takes the one that is from the right host
      linkout_url = nil
      
      get_linkouts(article).each do |link|
        if link =~ /www\.cancerimmunity\.org/
          linkout_url = link
        end
      end
      
      article.url = linkout_url

      doc, referer_url = CachedWebPage.get_cached_doc(:url=>linkout_url, :details=>true)
   
      path = nil
      if pdf_path = doc.at("a[text()='Printer-friendly PDF']")
        uri = URI.parse(referer_url)
        path = uri.merge(pdf_path['href']).to_s
      end
      
      unless path
        doc.search("a").each do |a|
          if a.inner_text =~ /Printer-friendly\s+PDF/
            uri = URI.parse(referer_url)
            path = uri.merge(a['href']).to_s
          end
        end
      end
    end
    puts "path: #{path}"
    path
  end
end
