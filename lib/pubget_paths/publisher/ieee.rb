class Publisher::Ieee < Publisher::Base

  def info()
    count = 0
    csv_url = "http://ieeexplore.ieee.org/otherfiles/OPACJrnList.txt"
    @cw = CachedWebPage.new
    @agent = HackedBrowser.new
    content = @cw.get_cached_url(:url=>csv_url, :expires_in => 1.month)
    # content = page.body
    actions = {:added=>0, :updated=>0, :total=>0}
    FasterCSV.parse(content) do |row|
      if row[0] =~ /TITLE/
        next 
      end
      #if journal_match = /"([^"]+)","([^"]+)",(\d\d\d\d-\d\d\d[\dXx]),(\d\d\d\d-\d\d\d[\dXx]),(\d\d\d\d-\d\d\d\d),([^,]+),"([^"]+)"/.match(line)
      # "TITLE","PUBLICATION NUMBER","START YEAR","END YEAR","CURRENT VOLUME","ISSUES PER YEAR","ISSN#","ADDED TO XPLORE","OPAC LINK (base url)","ASPP","IEL","AIP/AVS",
        # def update_source(publisher, grep, issn, eissn, title, title_abbreviation,
        #                      base_url, frame_busting, count, uncertain_title=true,
        #                      pdf_back=nil, pdf_start=nil, pdf_end=nil, secondary_source=true)
      title = row[0]
      issn = (row[6] =~ /not available/i) ? nil : row[6]
      if issn =~ /\d{8,8}/
        issn = "#{issn[0..3]}-#{issn[4..-1]}"
      end
      base_url = row[8]
      start_date = row[2]
      if start_date =~ /not available/i
        pdf_start = nil
      else
        pdf_start = Date.parse("#{row[2]}-01-01")
      end
      end_date = row[3]
      if end_date =~ /present|not available/i
        pdf_end = nil
      else
        pdf_end = Date.parse("#{row[3]}-12-31")
      end

      count += 1
      action = update_source("IEEE", nil, issn, nil, title, nil, base_url, false, count, false, nil, pdf_start, pdf_end, false)
      actions[:total] += 1
      if action == "added"
        actions[:added] += 1
      elsif action == "updated"
        actions[:updated] += 1
      end
    end
    CheckMonitor.checked("lister_info::ieee", 1.months, "Updated lister for IEEE", actions[:updated], actions[:added], actions[:total])
    puts actions.inspect
  end

end