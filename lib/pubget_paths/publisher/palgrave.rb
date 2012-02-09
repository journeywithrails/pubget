class Publisher::Palgrave < Publisher::Nature

  def info
    @agent = CachedWebPage.new
    journal_overview_page = @agent.get_cached_doc("http://www.palgrave-journals.com/pal/jnlindex.html")
    journal_overview_page.search("a.arrow-blue").each do |a|
      count = 0
      if a["href"] =~ /^\/\w+\/$/ #journal page link
        puts "getting #{a["href"]}"
        journal_page = @agent.get_cached_doc("http://www.palgrave-journals.com#{a["href"]}")
        pissn = nil
        if journal_page.at("p.issn")
          journal_page.at("p.issn").text =~ /issn: (.+?)$/i
          pissn = $1 if 1
        end  
        eissn = nil
        if journal_page.at("p.eissn")
          journal_page.at("p.eissn").text =~ /eissn: (.+?)$/i
          eissn = $1 if $1
        end
        title = journal_page.at("p.journal-name").text
        base_url = "http://www.palgrave-journals.com#{a["href"]}"
        count += 1
        puts "Saving journal #{title}: #{pissn}"
        if pissn or eissn
          update_journal("PalgraveMacmillan", nil, pissn, eissn, title, nil, base_url, nil, count)
        end
      end
    end
  end
end