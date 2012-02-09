class Publisher::Sage < Publisher::Highwire

  def info
    csv = FasterCSV.flexible_import("http://www.caul.edu.au/content/upload/files/datasets/sage2011titles.xls")
    count = 0
    actions = {:added=>0, :updated=>0, :total=>0}

    pubs = []
    domains = []
    csv.each do |row|
      #0 code, 1"Journal Name (updated 15 March 2010)",2 eissn, 3 print issn, 4 base_url
      next unless row[1] and row.size > 3
      title = row[1]
      unless title =~ /Journal Title/
        begin
          publisher = "Highwire"
          eissn = (row[2] =~ /\d\d\d\d-\d\d\d[\dXx]/) ? row[2] : nil
          pissn = (row[3] =~ /\d\d\d\d-\d\d\d[\dXx]/) ? row[3] : nil
          if eissn or pissn
            base_url = row[4] ? row[4].strip : nil
            count += 1
             action = update_journal("Highwire", nil, pissn, eissn, title, nil, base_url, true, count)
             actions[:total] += 1
             if action == "added"
               actions[:added] += 1
             elsif action == "updated"
               actions[:updated] += 1
             end
          end
        rescue
          puts "Error #{$!}: #{row}"
        end
      end
    end

    CheckMonitor.checked("lister_info::sage", 1.months, "Updated lister for Sage", actions[:updated], actions[:added], actions[:total])

  end

end