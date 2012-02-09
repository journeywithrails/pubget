class Publisher::Jstage < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    key = article.journal.base_url.split("/")[-2]
    "http://www.jstage.jst.go.jp/browse/#{key}/#{article.volume}/#{article.issue}/_contents"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true)
    lowest = 10 #get at least 10 but get the lowest
    path = nil
    doc.search("table table table").each do |table|
      if table.at("strong")
        term1 = table.at("strong").inner_html.split("<br").first
        term1 = term1 ? term1.downcase : ""
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          lowest = diff
          table.search("a").each do |a|
            path = "#{article.journal.journal_host}#{a['href']}" if a.render_to_plain_text =~ /PDF/
          end
        end
      end
    end
    
    unless path
       key = article.journal.base_url.split("/")[-2]
       archive_url = "http://www.journalarchive.jst.go.jp/english/jnltoc_en.php?cdjournal=#{key}1992&cdvol=#{article.volume}&noissue=#{article.issue}"
       doc, redirect_url = CachedWebPage.get_cached_doc(:url=>archive_url, :details=>true)
       lowest = 10 #get at least 10 but get the lowest
       path = nil
       doc.search("table table table tr").each do |table|
         if table.at("b")
           term1 = table.at("b").render_to_plain_text.downcase
           term2 = article.title.downcase
           diff = diff_string(term1, term2)
           if diff < lowest
              puts "Found a match #{diff}"
             lowest = diff
             table.next_sibling().search("a").each do |a|
               path = "http://www.journalarchive.jst.go.jp#{a['href'].gsub('..','')}" if a.render_to_plain_text =~ /PDF/
             end
           end
         end
       end
    end
    
    path
  end
  
  def openurl(params)
    article = params[:article]
    return "http://openurl.jlc.jst.go.jp/servlet/resolver01?sid=Entrez%3Apubget&genre=article&issn=#{ article.journal.issn}&date=#{article.article_date.year}&volume=#{article.volume}&issue=#{article.issue}&spage=#{article.start_page}&pid=lang_en"
  end
  
end