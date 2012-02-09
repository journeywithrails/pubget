class Publisher::Psychiatry < Publisher::Base
  
  def issue_url(params = {})
    article = params[:article]
    "#{article.journal.journal_host}/pastppp/tocs.asp?toc=t#{article.volume}#{article.issue.rjust(2,'0')}"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    
    # Primary Care Companion journal
    if article.pissn == "1523-5998"
      toc_url = "#{article.journal.journal_host}/pcc/tocs/pcc#{article.volume.rjust(2,'0')}#{article.issue.rjust(2,'0')}tc.htm"
      source = nil
      source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=> toc_url, :grep=>'psychiatry')
      doc = parse_html(source, toc_url)
      
      # look for the article title, then find the link with "Full Text" or "PDF" in it.
      term2 = article.title.downcase
      path = pdf_link = nil
      
      # We can't rely on the title being exact, so find all the paragraphs
      doc.search("p").each do |p|
        begin
          # paragraph can have multiple lines, the title is in the first line with text
          term1 = p.render_to_plain_text.strip.split(/\n/).first.downcase
          
          # if the first word is a number, chop it off
          term1 = term1[term1.index(/\s/), term1.size] if term1 =~ /\d{2,}/
          
          diff = String::diff_string(term1, term2)
          lowest = 10 #get at least 10 but get the lowest
          
          # if the difference between the title and the p content is smaller
          # it is a better match, so get the link related to this paragraph.
          if diff < lowest
            lowest = diff
            # there are two different structures for the toc of the PCC articles
            # PCC = Primary Care Companion
            # for examples see:
            # http://www.psychiatrist.com/pcc/tocs/pcc1202tc.htm
            # has the link inside a new paragraph following the paragraph containing the title
            # http://www.psychiatrist.com/pcc/tocs/pcc1106tc.htm
            # has the link inside the paragraph containing the title
            
            # find link 'PDF' within
            link_attrib = p.xpath("a[text()='PDF']/@href").first
            pdf_link = link_attrib.value if link_attrib
            node = p
            
            # if there is no PDF Link, look for the next link that has the text "Full Text"
            if pdf_link.nil?
              node = node.next_element.next_element
              link_attrib = node.xpath("a[text()='Full Text']/@href").first
              pdf_link = link_attrib.value if link_attrib
            end
          end
          
        rescue
          puts "#{__FILE__}:#{__LINE__}: #{$!}"
        end   
        
      end
        
      begin
        # the pdf is at the end of a redirect, need :details => true to get final URL
        path = pdf_link
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=> pdf_link, :details=>true) if pdf_link
        path = redirect_url if redirect_url
      rescue
        puts "#{__FILE__}:#{__LINE__}: #{$!}"
      end   
      
    else
      toc_url = "#{article.journal.journal_host}/pastppp/toc/t#{article.volume}#{article.issue.rjust(2,'0')}.htm"
      source = nil
      source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'psychiatry')
      doc = parse_html(source, issue_url(params))
      if doc.at("iframe#iframetoc")
         uri = URI.parse(issue_url(params))
         toc_url = "#{uri.merge(doc.at("iframe#iframetoc")['src'])}"
         source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>toc_url, :grep=>'psychiatry')
         doc = parse_html(source, toc_url)
      end
      lowest = 10 #get at least 10 but get the lowest
      term2 = article.title.downcase
      doc.search("td p").each do |p|
        begin
          term1 = p.render_to_plain_text.downcase
          term1 = term1[0,term2.length+4]
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            p.search("a").each do |a|
              path = URI.join(doc.url, a['href']).to_s if a.inner_text =~ /PDF/
            end
          end   
        rescue
          puts "#{__FILE__}:#{__LINE__}: #{$!}"
        end           
      end
    end
    path
  end  
end