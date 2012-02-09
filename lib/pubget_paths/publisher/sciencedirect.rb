class Publisher::Sciencedirect < Publisher::Base

  def info
    
    
    url = "http://ehr.sciencedirect.com/ehr/manageReports.url?_acctId=50221&_userId=10&_prodId=3&_platform=SD&_site=science&_env=SD&md5=209d13a5edc726678cc2e371f9cd4fb4"
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true, :expires_in=>1.months)
    uri = URI.parse(redirect_url)
    csv_link = uri.merge(doc.at("tr:nth-child(4) a")['href']).to_s
    
    if File.exists?("/tmp/sd.csv") and (File.ctime("/tmp/sd.csv") > 1.months.ago)
      source = File.new("/tmp/sd.csv", "r").read
    else
      source, redirect_url = CachedWebPage.get_cached_url(:url=>csv_link, :details=>true, :force=>true)
      File.open("/tmp/sd.csv", 'w') {|f| f.write(source) }
    end
    
    
    grep = nil
    count = 0

    source.split("\n").each do |line|
      begin
        row = FasterCSV.parse_line(line)
        #0Entitlement Status,1Publication Type,2Publication Name,3ISSN,4Publisher,5Entitlement Begins Volume,6Entitlement Begins Issue,
        #7Entitlement Begins Date,8Entitlement Ends Volume,9Entitlement Ends Issue,10Entitlement Ends Date,11Coverage Begins Volume,
        #12Coverage Begins Issue,13Coverage Begins Date,14Coverage Ends Volume,15Coverage Ends Issue,16Coverage Ends Date,
        #17Title Change History,18Remarks,19Short Cut URL
        if row and row[3] =~ /\d\d\d\d\-\d\d\d[\dXx]/
          base_url = "http://www.sciencedirect.com/science/journal/#{row[3].gsub('-','')}"
          puts row.inspect
          title = row[2]
          issn = row[3]
          pub_source = row[4]
          count = count + 1
          # def update_journal(publisher, grep, issn, eissn, title, title_abbreviation,
          #                     base_url, frame_busting, count, uncertain_title=true,
          #                     pdf_back=nil, pdf_start=nil, pdf_end=nil, secondary_source=false)
          if (pub_source == "Elsevier")
            update_journal("Sciencedirect", grep, issn, nil, title, nil, base_url,
              nil, count, false)
          else
            pdf_start = row[13].blank? ? nil : Date.date_from_string(row[13])
            pdf_end = nil
            if row[16].blank?
            elsif row[16] =~ /ongoing/i
            else
              pdf_end = Date.date_from_string(row[16], 'us', false)
            end
            update_source("Sciencedirect", nil, issn, nil, title, nil, nil, nil, count, uncertain_title=true, pdf_back=nil, pdf_start, pdf_end, secondary_source=true, certain_date=true)
          end
        end
      rescue
        puts "Erro #{$!}: #{line}"
      end
    end

      
  end
  
  @@sd_first_volume = Hash.new
  def issue_url(params={})
    article = params[:article]
    vol = article.volume.blank? ? '' : article.volume.gsub(' ', '%20')
    iss = article.volume.blank? ? '' : article.issue.gsub(' ', '%20')
    "http://www.sciencedirect.com/science/publication?" +
      "issn=#{article.journal.issn.gsub('-','')}&volume=#{vol}&issue=#{iss}"
  end

  def openurl(params={})
    article = params[:article]
    if article and article.url.present? and article.url.first =~ /article\/pii\//
      article.url.first
    elsif article and article.get_doi(params)
      ret_url = "http://dx.doi.org/#{article.doi}"
    elsif article.url.present? and article.url.is_a?(Array) and article.url.first.present?
      ret_url = article.url.first
    elsif article.url.present? and article.url.is_a?(String)
      ret_url = article.url
    elsif params[:inrequest].blank?
      article.get_url
    else
      nil
    end
  end
  
  def searchurl(params={})
    article = params[:article]
    "http://www.sciencedirect.com/science?_ob=QuickSearchURL&_method=submitForm&_acct=C000050221&_origin=home&_zone=qSearch&md5=b6cbf358cedf3c8cdd292afd6b3d8222&qs_all=&qs_author=&qs_title=#{article.journal_title}&qs_vol=#{article.volume}&qs_issue=#{article.issue}&qs_pages=#{article.start_page}&sdSearch=Search+ScienceDirect"
  end
  
  def pdf_url(params={})
    use_search = false
    begin
      #throw "test search"
      pdf_url = pdf_url_direct params
    rescue
      puts "exception in usual pdf_url"
      use_search = true
    end
    
    if use_search || !pdf_url
       puts "trying search"
       pdf_url = pdf_url_search params
    end

    pdf_url

  end
  
  def pdf_url_search params
    #searching by title and authors
    #returning first found result with appripriate diff for title    
    article = params[:article]
    
    pdf_url = nil
    
    agent = WWW::Mechanize.new
    agent.get("http://www.sciencedirect.com/")
    form = agent.page.form_with(:name=>'qkSrch')
    form.field_with(:name=>'qs_all').value = normalize_str(article.title)
    form.field_with(:name=>'qs_author').value = normalize_str(article.authors.last)
    form.submit
    parse = Nokogiri::HTML(agent.page.content)
    parse.search("#bodyMainResults >table >tr >td:eq(2) >a").each do |title|
       diff = diff_string(title.text.downcase, article.title.downcase)
       if diff < 10
         #puts "FOUND #{diff}"
         #$title = title
         pdf_url = title.attr("href").split('?')[0]
         break
       end
    end
    #$agent = agent
    #$parse = parse
    pdf_url
  end
  
  def pdf_url_direct(params={})
    article = params[:article]
 
    params[:use_pigeon] ||= false
    params[:force] ||= false
    #Scraping.require_implementation(:ScienceDirect)
    #scraper = Scraping::ArticleScrapers::ScienceDirect.new(nil, true)
    #pdf_url = scraper.calculate_pdf_url(self)
    #return pdf_url unless pdf_url.blank?

    if params[:inrequest]
      if article.get_pdf_url(source_name) and article.get_pdf_url(source_name) =~ /^http/
        return article.get_pdf_url(source_name)
      elsif article.url and article.url =~ /science\/article\/pii/
        return article.url
      else
        return openurl(params)
      end
    end

    path = nil
    @@sd_first_volume[article.issn] = 0 unless @@sd_first_volume[article.issn]
    if article.volume.to_i >= @@sd_first_volume[article.issn]
      
      source, redirect_url = CachedWebPage.get_cached_url(:url=>issue_url(params), :force=>false, :details=>true, :expires_in=>1.months)
      if source =~ /pubgetcacheerror|You have been temporarily denied access to the system/
        source, redirect_url = CachedWebPage.get_cached_url(:url=>issue_url(params), :expires_in=>1.days, :details=>true)
      end
      firstdoc = parse_html(source)
      docs = [firstdoc]
      
      # Check for suppl issues and missed ones
      firstdoc.search("a[text()*='Volume #{article.volume}, Issue #{article.issue.to_i}']").each do |a|
        #if a.inner_text =~ /Suppl/
        #  puts "Suppl issue as well: #{a.inner_text}"
          uri = URI.parse(issue_url(params))
          next_path = "#{uri.merge(a['href'])}"
          docs << CachedWebPage.get_cached_doc(:url=>next_path, :expires_in=>(params[:force] ? 1.days : 2.months))
        #end
      end
         
      # Check for next page      
      firstdoc.search("a[text()*='Next']").each do |a|
        unless a.inner_text =~ /vol/
          puts "Adding next page to be tested #{a['href']}"
          uri = URI.parse(issue_url(params))
          next_path = "#{uri.merge(a['href'])}"
          docs << CachedWebPage.get_cached_doc(:url=>next_path, :expires_in=>(params[:force] ? 1.days : 2.months))
          break
        end
      end
      
      docs.each do |doc|        
        lowest = 15 #get at least 15 but get the lowes
        if @@sd_first_volume[article.issn] == 0        
          @@sd_first_volume[article.issn] = 99999
          doc.search("table.pubBody td.txtBold a").each do |a|
            vol_match = /Volume ([\d]+) /.match(a.inner_text)
            vol_match = /Volumes ([\d]+) /.match(a.inner_text) unless vol_match
            if vol_match
              vol = vol_match[1].to_i
              @@sd_first_volume[article.issn] = vol unless @@sd_first_volume[article.issn]
              @@sd_first_volume[article.issn] = vol if (@@sd_first_volume[article.issn] > vol)
            end
          end
          @@sd_first_volume[article.issn] = 1 if @@sd_first_volume[article.issn] = 999
        end
        header = ""
        header = doc.at("title").inner_text if doc.at("title")
        vol_iss = Regexp.new("Volume #{article.volume}, Issue #{article.issue}")
        if article.issue =~ /suppl/i
           vol_iss = Regexp.new("Volume #{article.volume}, Supplement #{article.issue.to_i}")
        end
        unless vol_iss.match(header)
          puts "Not a volume/issue hit with: #{header}"
          doc.search("table.pubBody a").each do |a|
            if vol_iss.match(a.inner_text)
              issue_link = "http://www.sciencedirect.com#{a['href']}"
              doc = CachedWebPage.get_cached_doc(:url=>issue_link, :expires_in=>(params[:force] ? 1.days : 2.months))
              break
            end
          end
        end
        
        File.open(PUBLIC_BASE+"/result.html", "w") {|f| f.write(doc) }
        lowest = 15
        doc.search("div#bodyMainResults table").each do |table|
          unless article.url.present? and table.render_to_plain_text.blank?
            if table.at("a")
              term1 = table.at("a").render_to_plain_text.downcase
              term2 = article.title.downcase
              diff = diff_string(term1, term2)
              if diff < lowest
                lowest = diff
                table.search("a").each do |a|
                  if pii_match = /\/science\/article\/pii\/([A-Z0-9]+)\?/.match(a['href'])
                    article.url = "http://www.sciencedirect.com/science/article/pii/#{pii_match[1]}"
                    puts "Found: article.url\t#{article.url}"
                  end 
                  url = article.url.split("/pii/")
                  download_url = a['href'].split("&")
                  pii = download_url[4].split("=")              
                  path = a['href'] if a.render_to_plain_text =~ /PDF/ && a['target'] == 'newPdfWin' && url[1] == pii[1]
                end
              end  
            end
          end          
        end
        unless path
          doc.search("div#bodyMainResults table td").each do |table|
             unless article.url.present? and table.render_to_plain_text.blank?
               if table.at("span")
                 term1 = table.at("span").render_to_plain_text.downcase
                 term2 = article.title.downcase
                 diff = diff_string(term1, term2)
                 if diff < lowest
                   lowest = diff
                   #These types of pages are not even valid html - so use regex
                   if pdf_match = /a href="([\S]+sdarticle.pdf)"/.match(table.inner_html)
                      if pii_match = /\/science\/article\/pii\/([A-Z0-9]+)\?/.match(a['href'])
                        article.url = "http://www.sciencedirect.com/science/article/pii/#{pii_match[1]}"
                        puts "Found: article.url\t#{article.url}"
                      end
                      path = pdf_match[1]
                   end
                 end  
               end
             end
           end
        end
      end
    else
       puts "#{article.volume.to_i} >= #{@@sd_first_volume[article.issn]}"
    end
    unless path     
       #Try via the doi
       puts "Trying with #{article.get_doi}"
       source, redirect_url = CachedWebPage.get_cached_url(:details=>true, :url=>"http://dx.doi.org/#{article.get_doi}", :expires_in=>(params[:force] ? 1.days : 2.months))
      
      if source =~ /pubgetcacheerror/        
         source, redirect_url = CachedWebPage.get_cached_url(:details=>true, :url=>"http://dx.doi.org/#{article.get_doi}", :expires_in=>1.days)        
       end
       if source =~ /Elsevier:? Article Locator/i       
         if sd_match = /(href|value)="([\S]+www.sciencedirect.com\/science[^"]*)"/i.match(source)
            puts "Following link to: #{sd_match[2]}"
            source, redirect_url = CachedWebPage.get_cached_url(:details=>true, :url=>sd_match[2], :expires_in=>(params[:force] ? 1.days : 2.months))
         end
        #elsif source.blank?
        #  doi_search_url = "http://www.sciencedirect.com/science?_ob=MiamiSearchURL&_method=submitForm&_acct=C000014438&_temp=boolSearch.tmpl&md5=3f8f2339e1860f189968b0f499f15a5c&test_alid=&SearchText=doi%28#{article.doi}%29&Subscribed=0&aip=1&srcSel=1&DateOpt=2&fromDate=2001&toDate=Present&RegularSearch=Search"
        #  source, redirect_url = CachedWebPage.get_cached_url(:details=>true, :url=>doi_search_url, :expires_in=>(params[:force] ? 1.days : 2.months))
          
       end
       uri = URI.parse(redirect_url)       
       # Many proxy servers do not follow these links so not safe to use
       if uri.host == "www.cell.com"
          path = nil
       #  path = redirect_url.gsub("www", "download").gsub("retrieve", "pdf").gsub("pii/", "PII") + ".pdf"
       end
       
       unless path         
         doc = parse_html(source)       
         bad_links = []
         doc.search("div.infobubble-container a").each do |a|
           bad_links << a
         end
       
         doc.search("div.articlePage table a").each do |a|
           if a.render_to_plain_text =~ /PDF/ and not bad_links.include?(a)
             path = a['href'] 
             break #Don't look for any more
           end
         end
       end
       
       unless path         
         doc.search(".big").each do |a|
           if a.render_to_plain_text =~ /PDF/ and not bad_links.include?(a)
             path = a['href'] 
             break #Don't look for any more
           end
         end
       end       
    end
    
    path
  end
  
end