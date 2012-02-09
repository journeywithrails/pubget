class Publisher::Springer < Publisher::Metapress

  def info
    xls_file = "http://www.springer.com/cda/content/document/cda_downloaddocument/Springer+Journals+Price+List+2009_EUR_August+13?SGWID=0-0-45-599398-0"
    rows = FasterCSV.flexible_import(xls_file, "xls_url")
    count = 0
    rows.each do |row|
      #0Title	1Format	2Title No	3ISSN print	4ISSN electronic
      
      puts row.inspect
      
      if row[3] and (row[3] =~ /^\d\d\d\d-\d\d\d[\dxX]$/) and row[4] and (row[4] =~ /^\d\d\d\d-\d\d\d[\dxX]$/)
        title = row[0].strip
        issn = row[3].strip
    	  eissn = row[4].strip
    	  base_url = "http://metapress.com/openurl.asp?genre=journal&issn=#{issn}"
  	    count += 1
      	j = Journal.find_by_issn(issn)
      	j = Journal.find_by_issn(eissn) unless j
      	unless j
      	  j = Journal.new(:issn=>issn, :eissn=>eissn, :title=>title, :base_url=>base_url.gsub("www.springerlink", "metapress"), :publisher=>'metapress')
          j.save
        end
        unless Journal.find_by_issn(eissn)
          OldIssn.new(:issn=>issn, :old_issn=>eissn).save
        end
        #page, redirect_url = CachedWebPage.get_cached_doc(:url=>base_url.gsub("www.springerlink", "metapress"), :expires_in=>1.months, :details=>true)
        #update_journal_from_page(page, title, base_url, count)
      end
    end
  end
end