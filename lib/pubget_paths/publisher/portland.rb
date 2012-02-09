class Publisher::Portland < Publisher::Base
  
  def issue_url(params)
    article = params[:article]
    if article.volume
      "#{article.journal.base_url}#{article.volume.rjust(3,'0')}/#{article.issue.gsub('Pt ','') if article.issue}/default.htm?S=0"
    else
      "#{article.journal.base_url}"
    end
  end

  def openurl(params)
    article = params[:article]
    key = article.journal.base_url.split("/").last
    return "#{article.journal.base_url}#{article.volume.rjust(3,'0')}/#{key}#{article.volume.rjust(3,'0')}#{article.start_page.rjust(4,'0')}.htm"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    path = nil
    if article.volume
      key = article.journal.base_url.split("/")[-1]
      source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :grep=>'portland')
      doc = parse_html(source)
      if doc.at("title") && doc.at("title").inner_text =~ /contents/i
         lowest = 10 #get at least 10 but get the lowest
         term2 = article.title.downcase
         guess_abs = "#{article.journal.base_url}#{article.volume.rjust(3,'0')}/#{key}#{article.volume.rjust(3,'0')}#{article.start_page.rjust(4,'0')}.htm"
         guess_path = "#{article.journal.base_url}#{article.volume.rjust(3,'0')}/#{article.volume.rjust(3,'0')}#{article.start_page.rjust(4,'0')}.htm"
         doc.search("dl dt").each do |dl|
           term1 = dl.render_to_plain_text.downcase
           diff = diff_string(term1, term2)
           if diff < lowest
             lowest = diff
             dl.parent.search("a").each do |a|
               path = "#{article.journal.journal_host}#{a['href']}" if a['href'] =~ /pdf/i
             end        
           end      
         end
         unless path
           doc.search("a").each do |a|
              if a['href'] == "/#{key}/#{article.volume.rjust(3,'0')}/#{article.volume.rjust(3,'0')}#{article.start_page.rjust(4,'0')}.pdf"
                 path = guess_path
              elsif a['href'] == "/#{key}/#{article.volume.rjust(3,'0')}/#{key}#{article.volume.rjust(3,'0')}#{article.start_page.rjust(4,'0')}.htm"
                 adoc = parse_html(CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>guess_abs, :grep=>'portland'))
                 adoc.search("a.sidelinks").each do |a|
                     path = "#{article.journal.journal_host}#{a['href']}" if a['href'] =~ /pdf/i
                 end
              end
           end
         end
         unless path
           if article.get_doi
             source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>"http://dx.doi.org/#{article.get_doi}", :grep=>'portland', :expires_in=>2.days)
             doc = parse_html(source)
             doc.search("a").each do |a|
               if a['href'] =~ /pdf$/
                 uri = URI.parse(url_base = doc.at("meta[@name='DC.Identifier']")['content'])
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