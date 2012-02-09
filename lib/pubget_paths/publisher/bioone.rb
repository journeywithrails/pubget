class Publisher::Bioone < Publisher::Literatumonline
  def source_name
    "bioone"
  end
  def info

    index_url = "http://www.bioone.org/action/showPublications?type=byAlphabet"
    uri = URI.parse(index_url)
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>index_url, :grep=>'bioone', :user_agent=>"FAST", :details=>true)
    
    
    doc.search('div.browsePane').each do |div|
      title = nil
      base_url = nil
      info_url = nil
      count = 0
      if div.at('div.browseDesc')
        title = div.at('div.browseTitle a').inner_text.strip        
        div.search('div.browseDesc a').each do |a|
          if a.inner_text =~ /List of Issues/
            base_url = uri.merge(a['href']).to_s
          elsif a.inner_text =~ /Title Information/          
            info_url = uri.merge(a['href']).to_s
          end
        end
      end
      
      if title and base_url and info_url
        info_doc, redirect_url = CachedWebPage.get_cached_doc(:url=>info_url, :grep=>'bioone', :details=>true)
        if info_doc =~ /pubgetcacheerror/
          info_doc, redirect_url = CachedWebPage.get_cached_doc(:url=>info_url, :force=>true, :grep=>'bioone', :details=>true)
        end
          
        pissn, eissn, impact_factor = extract_issns(info_doc)
        
        puts "Found ISSN: #{pissn}/#{eissn} (#{impact_factor}) for #{title} at #{base_url}"
        unless pissn.blank? and eissn.blank?
          count += 1
          
          update_journal(source_name, nil, pissn, eissn, title, nil, base_url, true, count)
        else
          #get_cached_url(:url=>info_url, :force=>true, :grep=>'bioone', :slp=>5)
        end
      end
      
    end
    
  end
  
  def extract_issns(info_doc)
    pissn = nil
    eissn = nil
    impact_factor = nil
    
    info_doc.search("div#articleInfoBox p").each do |p|
      if  pissn.blank? and m = /(\d\d\d\d-\d\d\d[\dXx])/.match(p.inner_text)
        pissn = m[1] if m
      end
      if m = /Print\sISSN:\s(\d\d\d\d-\d\d\d[\dXx])/.match(p.inner_text)
        pissn = m[1] if m
      end
      if m = /Online\sISSN:\s(\d\d\d\d-\d\d\d[\dXx])/.match(p.inner_text)
        eissn = m[1] if m
      elsif pissn
        # No need to look for a solo issn
      elsif pissn.blank? and (m = /ISSN:\s(\d\d\d\d-\d\d\d[\dXx])/.match(p.inner_text))
        pissn = m[1] if m
      end
      if m = /Impact Factor:\s([\d\.].*)$/.match(p.inner_text)        
        impact_factor = m[1] if m
      end
    end
    
    [pissn, eissn, impact_factor]
  end
  
  
  def issue_url(params={})
    article = params[:article]
    if article.journal.base_url and article.volume and article.issue
      "#{article.journal.base_url.gsub('loi', 'toc')}/#{article.volume}/#{article.issue}"
    else
      nil
    end
  end

  def pdf_url(params={})
    article = params[:article]
    path = article.get_doi() ? "http://www.bioone.org/doi/pdf/#{article.get_doi()}" : nil
  end
end
