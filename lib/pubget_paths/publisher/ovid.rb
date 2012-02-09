class Publisher::Ovid < Publisher::Base
  
     
   def get_ovid_info(url, count, force=false)
     doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true, :expires_in=>1.months)
     tds = doc.search("td.bodytext td")
     if doc.at("span.booktitle")
       title = doc.at("span.booktitle").inner_text
       title = title.strip if title
       issn = nil
       eissn = nil
       pdf_coverage = nil
       pdf_start = nil
       pdf_end = nil
       if doc.at("span.sourcetitle").blank?
         publisher = "Ovid"
       else
         publisher = doc.at("span.sourcetitle").inner_text.gsub("Source: ","")
         publisher = "Ovid" if publisher =~ /LWW/
       end
       tds.each_with_index do |td,index|
         if td.inner_text == "ISSN:"
           issn = tds[index+1].inner_text.insert(4, "-")
          elsif td.inner_text == "EISSN:"
            eissn = tds[index+1].inner_text.insert(4, "-")
          elsif td.inner_text == "PDF Coverage:"
            pdf_coverage = tds[index+1].inner_text
         end
       end
       if pdf_coverage =~ /-/
        vol_match = /Vol[^\d]+([\d]{1,3}), Issue ([\d]{1,3})/i.match(pdf_coverage.split("-").first)
        vol_match = /Vol[^\d]+([\d]{1,3})\(([\d]{1,3})\)/i.match(pdf_coverage.split("-").first) unless vol_match
        if vol_match
          volume = vol_match[1]
          issue = vol_match[2]
          a = Article.raw_solr_query("issn:#{issn} volume:#{volume} issue:#{issue}", 1, [{"article_date" => :descending}, {"score" => :descending}])[0]
          if a
            start_date = a.article_date
          end
        else
          pdf_start = Date.date_from_string(pdf_coverage.split("-").first.strip)
        end
        vol_match = nil
        vol_match = /Vol[^\d]+([\d]{1,3}), Issue ([\d]{1,3})/i.match(pdf_coverage.split("-").last)
        vol_match = /Vol[^\d]+([\d]{1,3})\(([\d]{1,3})\)/i.match(pdf_coverage.split("-").last) unless vol_match
        if vol_match
          volume = vol_match[1]
          issue = vol_match[2]
          a = Article.raw_solr_query("issn:#{issn} volume:#{volume} issue:#{issue}", 1, [{"article_date" => :ascending}, {"score" => :descending}])[0]
          if a
            pdf_end = a.article_date
          end
        else
          pdf_end = Date.date_from_string(pdf_coverage.split("-").last.strip) unless pdf_coverage.split("-").last =~ /Pre([sent]+)?/i
        end
       end
       puts "#{issn}:#{pdf_start} to #{pdf_end}"
       update_source("Ovid", nil, issn, eissn, title, nil, nil, nil, count, uncertain_title=true, pdf_back=nil, pdf_start, pdf_end, secondary_source=true, certain_date=true)
     end
   end
   
   def info
     
     url = "http://www.ovid.com/site/catalog/Catalog_Journal.jsp"
     doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true, :expires_in=>1.months)
     uri = URI.parse(redirect_url)
     links = []
     count = 0
     actions = {:added=>0, :updated=>0, :total=>0}
     
     doc.search("a").each do |a|
       if a["href"] =~ /\/site\/catalog\/Journal\//
         count += 1
         actions[:total] += 1
         actions[:updated] += 1
         get_ovid_info(uri.merge(a['href']).to_s, count)
       end
     end
     
     CheckMonitor.checked("lister_info::ovid", 1.months, "Updated lister for Oxford", actions[:updated], actions[:added], actions[:total])
     
    end
    
  attr_accessor :article, :agent

  def pdf_url(params={})
    self.article = params[:article]
    self.agent = WWW::Mechanize.new()
    ppv_url = "http://ovidsp.ovid.com/ovidppv.cgi"

    #path = nil
    if params[:inrequest]
      openurl(params)
    elsif params[:inrequest] and article.pdf_path and (article.pdf_path =~ /AN=/)
      article.pdf_path
    elsif params[:inrequest] and article.get_pdf_url("ovid") and (article.get_pdf_url("ovid") =~ /AN=/)
      article.get_pdf_url("ovid")
    else
      puts "Getting the form page..."
      search_form_page = agent.get(ppv_url)
      form = search_form_page.form_with(:name => "sfovidclassic")
      return nil unless form

      field = form.field_with(:name => "textBox")
      radio = form.radiobutton_with(:value => "Title")
      return nil if not field or not radio

      field.value = article.title
      radio.check

      puts "Done. Sending the search request..."
      if an = page_search(form.submit)
        path = "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=#{an}"
        if article.pdf_path and article.pdf_path =~ /ovid\.com/
          article.url = path
        end
        path
      else
        openurl(params)
      end
    end
  end

  def page_search(page, page_num = 1)
    puts "Searching on the page..."
    results_selector = "td.titles-record"
    title_selector = "div.article-title a.tlink"
    an_selector = "div.article-ui"
    max_diff = 15
    match = nil
    results = page.search(results_selector)

    results.each_with_index do |result, i|
      title_value = result.search(title_selector).text
      current_diff = String.diff_string(article.title, title_value)
      next if current_diff > max_diff

      max_diff = current_diff if current_diff < max_diff
      match = results[i]
    end

    unless match
      puts "No matches found."
      return nil if page_num > 1

      puts "Switching the page number #{page_num + 1}..."
      form = page.forms.last
      page_seacrh(form.submit(form.button_with(:value => "Next ▶")), page_num + 1)
    else
      an = match.search(an_selector)
      an ? an.children.last.text.strip.gsub(/\.$/, '') : nil
    end
  end

  def openurl(params={})
    article = params[:article]
    transform = params[:transform]
    if article.accession_number.blank?
      if article.exists_on_pubmed and (transform and transform.ovid_prmz == 1)
        "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=prmz&MODE=ovid&NEWS=N&SEARCH=#{article.pmid}.ui"
      elsif article.primary_issn and article.issue =~ /^[\d]+$/ and article.volume =~ /^[\d]+$/ and article.start_page =~ /^[\d]+$/
        "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&SEARCH=#{article.primary_issn}.is+and+#{article.volume}.vo+and+#{article.issue}.ip+and+#{article.start_page}.pg"
      elsif not article.doi.blank?
        "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&SEARCH=%22#{article.doi}%22.di"
      else
        return nil if article.pagination.blank? or article.issue.blank? or article.start_page.blank?
        ov_issue = article.issue
        ov_issue = article.issue.gsub(/ Suppl/i, '') if article.issue and article.issue =~ / Suppl/i
        "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&SEARCH=#{article.primary_issn}.is+and+#{article.volume}.vo+and+#{ov_issue}.ip+and+#{article.start_page}.pg"
      end
    else
      "http://ovidsp.ovid.com/ovidweb.cgi?T=JS&PAGE=fulltext&CSC=y&D=ovft&MODE=ovid&NEWS=N&AN=#{article.accession_number}"
    end
  end
end
