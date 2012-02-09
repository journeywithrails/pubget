class Publisher::BMJ < Publisher::Highwire
  
  def info
    resource_list = "http://group.bmj.com/products/journals"
    
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>resource_list, :details=>true, :expires_in=>1.months)
    actions = {:added=>0, :updated=>0, :total=>0}
    count = 0
    doc.at("#resource_name").search('option').each do |option|
      
      if option['value'] =~ /^http/
        jdoc, redirect_url = CachedWebPage.get_cached_doc(:url=>option['value'], :details=>true, :expires_in=>1.months)
        div = jdoc.at("#footer p")
        if div and (issn_match = /Online ISSN[^\d]+(\d\d\d\d\-\d\d\d[xX\d])/.match("#{div.inner_text}"))
          eissn = issn_match[1]
          base_url = option['value']
          title = option.inner_text
          title_abbreviation = nil
          if title_parts = /([^(]+)\s\(([^\)]+)/.match(title)
            title = title_parts[1]
            title_abbreviation = title_parts[2]
          end
          count += 1
          actions[:updated] += 1
          puts "Update eissn: #{eissn}"
           action = update_journal("BMJ", nil, nil, eissn, title, title_abbreviation, base_url, true, count)
            actions[:total] += 1
            if action == "added"
              actions[:added] += 1
            elsif action == "updated"
              actions[:updated] += 1
            end
        end
      end
    end
    
    CheckMonitor.checked("lister_info::bmj", 1.months, "Updated lister for BMJ", actions[:updated], actions[:added], actions[:total])
    
  end

  def issue_url(params)
    highwire = Publisher::Highwire.new
    highwire.issue_url(params)
  end
  
  def pdf_url(params={})
    params[:use_pigeon] ||= false
    highwire = Publisher::Highwire.new
    highwire.pdf_url(params)
  end

end