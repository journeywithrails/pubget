class Publisher::Jstor < Publisher::Base
  
  def info
    
    url = "http://www.jstor.org/action/showJournals"
    
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :expires_in=>1.months)
    
    doc.search("a").each do |a|
    
      if code = /\/showPublication\?journalCode\=([a-z]+)$/.match(a['href'])
        info_url = "http://www.jstor.org/action/showPublicationInfo?journalCode=#{code[1]}"
        info_doc, redirect_url = CachedWebPage.get_cached_doc(:url=>info_url, :expires_in=>1.months)
        if issn_match = info_doc.at("div.issn")
          if issn = /ISSN: ([0-9]{7}[0-9X]{1})/.match(issn_match.inner_text)
            title = info_doc.at("h2").inner_text
            pissn = issn[1][0,4] + "-" + issn[1][4,8]
            eissn = nil
            publisher = nil
            if eissn_div = info_doc.at("div.eissn")
              if issn = /E-ISSN: ([0-9]{7}[0-9X]{1})/.match(eissn_div.inner_text)
                eissn = issn[1][0,4] + "-" + issn[1][4,8]
              end
            end
            if pub_a = info_doc.at("div.pubString a")
              publisher = pub_a.inner_text
            end
            puts "#{pissn}: #{title}"
            j = Journal.find_by_issn(pissn)
            if eissn.present? and j.blank?
              j = Journal.find_by_issn(eissn)
            end
            unless j
              j = Journal.new(:eissn=>eissn, :issn=>pissn, :title=>title, :publisher=>publisher)
              j.save
            end
          end
        end
      end
    end
  end
  
  
  def issue_url(params={})
    article = params[:article]
    "http://www.jstor.org/sici?sici=#{article.journal.primary_issn}(#{article.article_date.year}#{article.article_date.month})#{article.volume}:#{article.issue}%3C%3E2.0.CO;2-#&origin=sfx%3Asfx"
  end
  
  def openurl(params={})
    article = params[:article]
    if article.get_pdf_url('jstor')
      stable_pdf = article.get_pdf_url('jstor')
      if key = /stable\/pdfplus\/([0-9]+)\.pdf/.match(stable_pdf)
        return "http://www.jstor.org/stable/#{key[1]}"
      end
    end
    
    return "http://www.jstor.org/sici?sici=#{article.journal.primary_issn}(#{article.article_date.year}#{article.article_date.month})#{article.volume}:#{article.issue}%3C#{article.start_page}:%3E2.0.CO;2-#&origin=sfx%3Asfx"
  end
  
  def pdf_url(params={})
    article = params[:article]
    
    params[:use_pigeon] ||= false
    # First try the issue page
    isource = CachedWebPage::get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'jstor')
    
    if isource =~ /An Error Occurred Setting Your User Cookie/
      isource = CachedWebPage::get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'jstor', :force=>true)
    end
    
    idoc = parse_html(isource)        
    stable_url = nil
    path = nil
    lowest = 10
    
    term2 = article.title.downcase
        
    idoc.search("div#results li").each do |li|
      if a = li.at("a")
        term1 = a.render_to_plain_text.downcase
        term1 = @@ic.iconv(term1)
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          stable_url = "http://www.jstor.org#{a['href']}" if a['href'] =~ /stable/i
        
          if stable_url and stable_url =~ /\?/
            stable_url = stable_url.to_s.split('?').first
          end        
        end  
      end    
    end
    
    
        
    unless stable_url
      source = CachedWebPage::get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>openurl(params), :grep=>'jstor')
      
      if source =~ /An Error Occurred Setting Your User Cookie/
        source = CachedWebPage::get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>openurl(params), :grep=>'jstor', :force=>true)
      end

      doc = parse_html(source)
      
      doc.search("ul li").each do |li|
        if stable_match = /^Stable URL: (.*)/.match(li.inner_text)
          stable_url = stable_match[1]
        end
      end
    end
    
    if stable_url
      if stable_number = /http:\/\/www\.jstor\.org\/stable\/([0-9]{3,10})/.match(stable_url)
        path = "http://www.jstor.org/stable/pdfplus/#{stable_number[1]}.pdf"
      end
    end
    path
  end
end