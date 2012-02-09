class Publisher::Crd < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = search_by_title(article)

    url
  end

  def search_by_title(article)
    atitle = raze(article.title)
    search_url = "http://www.crd.york.ac.uk/CRDWeb/ResultsPage.asp?RecordsPerPage=20&SearchFor=#{atitle[/\w[\w\s]{35}[\w]*/]}"
    search_doc = CachedWebPage.get_cached_doc(:url => search_url, :grep => 'crd', :expired_in => 1.weeks)
    search_results = search_doc.search("div#print_content > table > tr")
    return nil unless search_results

    match = nil

    search_results.each do |result|
      title_elem = result.at('td.ResultsTableCitation > span')

      if title_elem
        title = raze(title_elem.render_to_plain_text)
        match = title_elem if atitle == title
      end
    end

    unless match
      max_diff = 10

      search_results.each do |result|
        title_elem = result.at('td.ResultsTableCitation > span')

        if title_elem
          title = raze(title_elem.render_to_plain_text)
          diff = diff_string(atitle, title)
          if diff < max_diff
            max_diff = diff
            match = title_elem
          end
        end
      end
    end

    if match and match['onclick'].scan(/\"(\d+)\",.*/)
      "http://update-sbs.update.co.uk/CMS2Web/tempPDF/#{match['onclick'].match(/\"(\d+)\",.*/)[1]}.pdf"
    end
  end
end