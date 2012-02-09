class Publisher::Mdconsult < Publisher::Base
  def source_name
    "mdconsult"
  end
  
  def info
    urls = [
      "http://www.mdconsult.com/das/journallist/body/206141180-2",
      "http://www.mdconsult.com/das/clinicslist/body/206301256-2"
      ]
    count = 0
    
    urls.each do |url|
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true, :expires_in=>1.month)
      sources = sources_from_doc(doc)
      source.each do |source|
        count += 1
        update_source(source_name, nil, source[:issn], nil, source[:title], nil, nil, nil, count, uncertain_title=true, pdf_back=nil, source[:start_date], source[:end_date], secondary_source=true, certain_date=true)
      end
    end
    
  end
  
  def sources_from_doc(doc)
    sources = []
    doc.search(".browselist li").each do |li|
      journal_title = nil
      coverage = nil
      j = nil
      li.search("a").each do |a|
        span_text = a.inner_text.strip
        if span_text =~ /Full text available from/
          coverage = span_text
        else
          journal_title = span_text
        end
        if issn_match = /issn=(\d{4}-\d{3}[\dxX]{1})$/.match(a['href'])
          j = Journal.find_by_issn(issn_match[1])
          journal_title = j.title
        end
      end
      li.search("span").each do |span|
        span_text = span.inner_text.strip
        if span_text =~ /Full text available from/
          coverage = span_text
        else
          journal_title = span_text if journal_title.blank?
        end
      end
      if journal_title
        j = Journal.find_by_title_or_alias(journal_title) unless j
        if j and coverage
          coverage = coverage.gsub("Full text available from ","")
          cov_parts = coverage.split(" - ")
          pdf_start = Date.date_from_string(cov_parts[0])
          pdf_end = nil
          pdf_end = Date.date_from_string(cov_parts[1]) unless cov_parts[1] =~ /present/i
          sources << {:issn=>j.issn, :title=>j.title, :start_date=>pdf_start, :end_date=>pdf_end}
          puts "Coverage: #{j.issn}\t#{coverage}"
        elsif coverage.blank?
          puts "No coverage: #{journal_title}"
        else
          puts "Cannot find: #{journal_title}"
        end
      end
    end
    puts "Sources: #{sources.size}"
    sources
  end
  
  def pdf_url(params={})
    article = params[:article]
    pdf_url = openurl(params)
    if params[:inrequest]
      return pdf_url
    end
    doc = CachedWebPage::get_cached_doc pdf_url
    if doc.to_s.include? "General Error"
      pdf_url = search_by_doi(article)
      
      if pdf_url =~ /body\/\d+-\d+\/jorg/
        pdf_url.gsub!(/body\/(\d+-\d+\/)jorg/, "body/jorg")
      end
      
      if pdf_url =~ /\&sid\=/
        pdf_url.gsub!(/(\&sid\=\d+)\/N/, "/N")
      end
    end
    article.url = pdf_url unless pdf_url.nil?
    pdf_url    
  end
  
  def search_by_doi article
    
    pdf_url = nil
    lowest_diff = 10
    if article.doi
      
      doc = CachedWebPage::get_cached_doc("http://www.mdconsult.com")
      link = "http://www.mdconsult.com/"+doc.search("a[@title*='Journals/MEDLINE']").attr("href").to_s
      agent = WWW::Mechanize.new
      agent.get link
      #agent.get("http://www.mdconsult.com/das/journallist/body/283622460-1432")
      
      form = agent.page.form_with(:name=>'search_form')
      form.field_with(:name=>'srchsection').value = "All"
      form.field_with(:name=>'term1').value = article.doi
      form.submit
      parse = Nokogiri::HTML(agent.page.content)
      parse.search("tr.odd td:eq(1), tr.even td:eq(1)").each do |link|
        a = link.search('a').first
        diff = diff_string(article.title.downcase,a.text.downcase,lowest_diff)
        if diff<lowest_diff
          lowest_diff = diff
          pdf_url = "http://www.mdconsult.com#{a[:href]}"          
        end
      end
    end

    if pdf_url
      #get redirection url
      agent.get pdf_url
      pdf_url = agent.page.uri.to_s
    end
    pdf_url
    
  end
    
    
  
  def openurl(params={})
    article = params[:article]
    if article.article_date and article.article_date.year > 1979 and article.repo.include?('pubmed')
      "http://home.mdconsult.com/public/journal/view?j_date_range=1980-current&pubmedid=#{article.pmid}"
    else
      nil
    end
  end
end
