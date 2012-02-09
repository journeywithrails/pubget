class Publisher::Metapress < Publisher::Base
  
   def info
      puts "getting first page"
      count = 0
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://metapress.com/journals/?sortorder=asc&o=#{count}", :expires_in=>1.months, :details=>true)
      
      pages = 329
      if doc.at("#ctl00_MainPageContent_ctl03_ctl00_ctl20_ctl00_ctl00 td:nth-child(1)")
        if journ_match = /^(.+) Journal/.match(doc.at("#ctl00_MainPageContent_ctl03_ctl00_ctl20_ctl00_ctl00 td:nth-child(1)").inner_text)
          pages = journ_match[1].to_i/10
          puts "Found: #{pages} pages"
        end
      end
      
      329.times do
         puts "going through doc"
         doc.search("span.listItemName a").each do |a|
            title = a.inner_text.strip
            base_url = "http://metapress.com#{a['href']}"
            base_url = base_url.gsub(base_url.split("/").last, "")
            page, redirect_url = CachedWebPage.get_cached_doc(:url=>base_url, :expires_in=>1.months, :details=>true)
            update_journal_from_page(page, title, base_url, count)
         end
         count = count + 1
         doc, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://metapress.com/journals/?sortorder=asc&o=#{count}0", :expires_in=>1.months, :details=>true)
         
      end
      metapress_journal_overrides
      
      #Document the free ones
      journal_ids, j_map = build_jid_list
      access = []
       
      journal_ids.chunk_array(10).each do |chunk|
        puts "Getting chunk..."
        access_source = 
        CachedWebPage.new.fetch_cache(:key=>key, :expires_in=>expires_in) do
          get_metapress_rights(nil, chunk, @agent)
        end
        access.each_index do |index|
          ac = access[index]
          jid = chunk[index]
          j = j_map[jid]
          start_date = nil
          end_date = nil
          if ac.to_i == 3 #open
            #This is a free journal
          end
        end
      end
      
   end
   
  def update_journal_from_page(page, title, base_url, count)
    page.search("tr").each do |tr|
      col1 = tr.at("td.labelName").inner_text if tr.at("td.labelName")               
      if col1 =~ /ISSN/
         issns = tr.at('td.labelValue').inner_text
         issns = issns.split
         issn = issns[0]
         eissn = issns[2] if issns.size > 2
         update_journal(source_name, nil, issn, eissn, title, nil, base_url, nil, count, false)
      end
    end
  end
   
  def metapress_journal_overrides
     update_journal("Metapress", "metapress_without_linkout", "0364-2313",
       "1432-2323", "World Journal of Surgery", nil, "http://metapress.com/content/101185/", nil, nil,
       uncertain_title=false)
  end
  
  def openurl(params)
    article = params[:article]
    if article.volume =~ /Suppl/
      "http://metapress.com/openurl.asp?genre=article&issn=#{article.journal.pissn}&volume=#{article.volume.split[0]}&issue=1&spage=#{article.start_page}"
    elsif article.volume
       "http://metapress.com/openurl.asp?genre=article&issn=#{article.journal.pissn}&volume=#{article.volume.split[0]}&issue=#{article.issue}&spage=#{article.start_page}"
    else
      "http://metapress.com/openurl.asp?genre=journal&issn=#{article.journal.pissn}"
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    article.metapress_pdf_url
    params[:use_pigeon] ||= false
    path = nil
    
    source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :slp=>1, :grep=>'metapress')
    puts issue_url(params)
    doc = parse_html(source)
    page_table = doc.at("table.paginationControl")
    if page_table
      page_table.search("a").each do |a|
         source = source + CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>"http://metapress.com#{a['href']}", :slp=>1, :grep=>'metapress') unless a.render_to_plain_text =~ /Next/
      end
    end
    
    path = parse_metapress(article, source)
    
    unless path
       #guess via doi
       if article.get_doi
         #puts "Try via #{get_doi}"
         url = "http://metapress.com/openurl.asp?genre=article&id=doi:#{article.get_doi}"
         source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>url, :slp=>1, :grep=>'metapress')
         doc = parse_html(source)   
         doc.search("div.resourceLinks a").each do |a|
            path = a['href'] if a.render_to_plain_text =~ /PDF/
         end
         doc.search("div.mainPageContentHeading a").each do |a|
            path = a['href'] if a.render_to_plain_text =~ /PDF/
         end
         path = "http://metapress.com#{path}" if path
         
         unless path
           url = "http://dx.doi.org/#{article.get_doi}"
           source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>url, :slp=>1, :grep=>'metapress', :expires_in=>2.days)
           doc = parse_html(source)   
           doc.search("div.resourceLinks a").each do |a|
              path = a['href'] if a.render_to_plain_text =~ /PDF/
           end
           doc.search("div.mainPageContentHeading a").each do |a|
              path = a['href'] if a.render_to_plain_text =~ /PDF/
           end
           path = "http://metapress.com#{path}" if path
         end
         #puts "Found: #{path}"
       end
    end
    
    unless path
        #guess via openurl if we have a valid start page
        if not article.start_page.blank?
          url = "#{issue_url(params)}&spage=#{article.start_page.gsub(/\D/,'')}"
          source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>url, :slp=>1, :grep=>'metapress')
          doc = parse_html(source)   
          doc.search("div.resourceLinks a").each do |a|
             path = a['href'] if a.render_to_plain_text =~ /PDF/
          end
          path = "http://metapress.com#{path}" if path
        end
    end
    
    unless path
       key = nil
       img = doc.at("td.MPReader_Profiles_Www_Content_PrimitiveHeadingControlCoverImage img")
       if img
          if key_match = /\/content\/([^\/]+)\//.match(img['src'])
            key = key_match[1]
          end
        end
       search_url = "http://metapress.com/content/#{key}/?k=#{article.title}"
       source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>search_url, :slp=>1, :grep=>'metapress')
       path = parse_metapress(article, source)
    end
    
    path
  end
  
  def parse_metapress(article, source)
    path = nil
    doc = parse_html(source)   
    lowest = 10 #get at least 10 but get the lowes
    tables = doc.search("td.viewItem")
    tables.each do |table|
      unless table.render_to_plain_text.blank?
        if table.at("div.listItemName")
          term1 = table.at("div.listItemName").render_to_plain_text.downcase
          term2 = article.title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            table.search("td.resourceLinks a").each do |a|
              path = a['href'] if a.render_to_plain_text =~ /PDF/
            end
          end  
        end
      end
    end
    path = "http://metapress.com#{path}" if path
    path
  end
  
  def issue_url(params= {})
    article = params[:article]
    if article.volume =~ /Suppl/
      "http://metapress.com/openurl.asp?genre=journal&issn=#{article.journal.pissn}&volume=#{article.volume.split[0]}&issue=1"
    elsif article.volume
       "http://metapress.com/openurl.asp?genre=journal&issn=#{article.journal.pissn}&volume=#{article.volume.split[0]}&issue=#{article.issue}"
    else
      "http://metapress.com/openurl.asp?genre=journal&issn=#{article.journal.pissn}"
    end
  end

end