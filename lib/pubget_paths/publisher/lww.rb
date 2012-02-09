class Publisher::LWW < Publisher::Base

  def info
    publisher = "LWW"
    count = 0
    ("A".."Z").each do |letter|
      jurl = "http://journals.lww.com/pages/default.aspx?filter=#{letter}"
      jlist = CachedWebPage.get_cached_doc(:url=>jurl)
      
      jlist.search("h4.ej-article-title-fluid a").each do |a|
        title = a.inner_text.strip
        puts "Found #{title}"
        j = Journal.find_by_title(title)
        issn = nil
        eissn = nil
        base_url = a['href'].strip
        
        puts "base_url: #{base_url}"
        
        if eissnp = a.parent.parent.at("p.ej-featured-article-online-issn")
         eissn = eissnp.inner_text.split(":").last.strip
        end
        if issnp = a.parent.parent.at("p.ej-featured-article-issn")
          issn = issnp.inner_text.split(":").last.strip
        end
        if impact_factorp = a.parent.parent.at("p.ej-featured-article-impact")
           impact_factor = impact_factorp.inner_text
         end
         
        count = count + 1
        update_journal(publisher, nil, issn, eissn, title, nil, base_url, nil, count)
      end
    end
  end


  def issue_url(params={})
    article = params[:article]
    key_match = /pt\/re\/([\S]+)\/issue/.match(article.journal.base_url)
    key_match = /http:\/\/journals.lww.com\/([\S]+)$/.match(article.journal.base_url) unless key_match
    if key_match
       key = key_match[1]
       if params[:inrequest]
         return "#{article.journal.journal_host}/pt/re/#{key}/issuelist.htm"
       else
         issue_list = "http://journals.lww.com/#{key}/pages/issuelist.aspx?year=#{article.year}"
         doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_list, :details=>true, :expires_in=>((article.year == Date.today.year) ? 7.days : 3.months), :user_agent => "Mozilla/5.0")
         uri = URI.parse(redirect_url)
         doc.search("a").each do |a|
           if vol_iss_match = /Volume ([\d]{1,5}).+Issue ([\d]{1,3})/.match(a.inner_text)
             if (article.volume == vol_iss_match[1]) and (article.issue == vol_iss_match[2]) 
               return uri.merge(a['href']).to_s
             end
           elsif vol_iss_match = /Volume ([\d]{1,5}).+Supplement ([\d]{1,3})/.match(a.inner_text) 
             if article.issue =~ /([\d{1,3}]) Suppl/ and $1 == vol_iss_match[2]
               return uri.merge(a['href']).to_s
             end
           end
         end
       end
       "#{article.journal.base_url}/toc/publishahead"
    elsif article.issue.blank? and (article.journal.base_url =~ /journals\.lww\.com\//)
      "#{article.journal.base_url}/toc/publishahead"
    else
       article.journal.base_url
    end
  end

  def pdf_url(params={})
    article = params[:article]
    path = nil
    fulltext_a = nil
    unless issue_url(params).blank?
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true, :expires_in=>((issue_url(params) =~ /publishahead/) ? 1.days : 3.months), :user_agent => "Mozilla/5.0")
      lowest = 10 # get at least 10 but get the lowest
      doc.search("div#ej-featured-article-info").each do |div|
        term1 = div.at("h4 a").render_to_plain_text.downcase
        term1_short = term1.split(":").first # some titles do not have text after ":" saved
        term2 = article.title.downcase
        diff = [diff_string(term1, term2), diff_string(term1_short, term2)].min
        # check for title match
        if diff < lowest
          puts "Found possible title match #{diff}"
          fulltext_a = div.at("h4 a")['href'] # url for fulltext in case there is no buy link
          lowest = diff
          buy_a = nil
          # search the div for a buy link
          div.search("a").each do |a|
            buy_a = a if a.text =~ /Purchase Access/
          end
          # check url of buy_a for accession number
          if buy_a and an_match = /an=([0-9]{7,9}\-[0-9]{8,10}\-[0-9]{4,6})$/.match(buy_a['href'])
            an = an_match[1]
            puts "Found buy link #{an}"
            path = "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=#{an}"
            article.add_pdf_url(path, 'ovid')
            article.save
          end
        end
      end
    end
    unless (article.get_pdf_url("ovid") and (article.get_pdf_url("ovid") =~ /AN=/))
      cw = CachedWebPage.new
      doc, redirect_url = cw.get_cached_doc(:url=>fulltext_a, :details=>true, :expires_in=>4.days, :user_agent => "Mozilla/5.0")
      an = nil
      doc.search("a").each do |a|
        if an and path
          break # no need to keep searching
        end
        if an_match = /an=([0-9]{7,9}\-[0-9]{8,10}\-[0-9]{4,6})$/.match(a['href'])
          an = an_match[1]
        end
        if /Article as PDF/.match(a.render_to_plain_text)
          path = a['href']
        end
      end
      if meta_tag = doc.at("meta[@name='wkhealth_ovid_accession_number']")
        an = meta_tag['content']
      elsif an_match = /OvidAN = '([0-9]{7,9}\-[0-9]{8,10}\-[0-9]{4,6})'/.match(doc.inner_html)
        an = an_match[1]
      end
      if an
        puts "Found AN: #{an}"
        path = "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=#{an}" unless path
        article.add_pdf_url("http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=#{an}", 'ovid')
        article.save
      end
    end
    path
  end
end