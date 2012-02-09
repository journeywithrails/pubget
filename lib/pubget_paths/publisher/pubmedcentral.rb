class Publisher::Pubmedcentral < Publisher::Base
  def info
    
    csv_file = "http://www.ncbi.nlm.nih.gov/pmc/journals/?format=csv"
    count = 0
    @agent = HackedBrowser.new
    page = @agent.get(:url=>csv_file)
    content = page.body
    issns = []
    actions = {:added=>0, :updated=>0, :total=>0}
    content.split("\n").each do |line|
      row = CSV.parse_line(line)
      # Journal title,NLM TA,pISSN,eISSN,Publisher,LOCATORplus ID,Latest issue,Earliest volume,Free access,Open access,Participation level, Deposit status, Journal URL
      publisher = row[4]
      
      
      title = row[0]
      pissn = (row[2] == "N/A") ? nil : row[2]
      eissn = (row[3] == "N/A") ? nil : row[3]
      next unless pissn =~ /\d\d\d\d-\d\d\d[\dXx]/
      next unless eissn =~ /\d\d\d\d-\d\d\d[\dXx]/
      base_url = nil
      issns << pissn if pissn
      issns << eissn if eissn
      unless (publisher =~ /publisher/i)
        count += 1
        
        action = update_source(publisher, nil, pissn, eissn, title, nil, nil, true, count)
        actions[:total] += 1
        if action == "added"
          actions[:added] += 1
        elsif action == "updated"
          actions[:updated] += 1
        end
      end
    end
    CheckMonitor.checked("lister_info::pubmedcentral", 1.months, "Updated lister for Pubmedcentral", actions[:updated], actions[:added], actions[:total])
  end  
  
  # Special case - managed elsewhere
end
