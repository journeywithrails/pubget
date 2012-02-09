class Publisher::KoreanDermatology < Publisher::Base
  
  def info
    title = "Annals of Dermatology"
    base_url = "http://pdf.medrang.co.kr/Aod/"
    update_journal("KoreanDermatology", nil, "1013-9087", "2005-3894", title, nil, base_url, nil, 1, uncertain_title=false)
    CheckMonitor.checked("lister_info::KoreanDermatology", 1.years, "Updated info for Korean Dermatology", 1, 0, 1)
  end
  
  
  def issue_url(params={})
    article = params[:article]
    if article.year.present? and article.volume.present? and article.issue.present?
      year   = article.year
      volume = article.volume
      issue  = article.issue
      "http://anndermatol.org/journal/list.html?start=&mod=vol&scale=10&book=Journal&Vol=#{volume}&Num=#{issue}&year=#{year}&aut_box=Y&sub_box=Y&pub_box=Y"
    else
      nil
    end
  end
  
  def pdf_url(params)
    article = params[:article]
    path = nil

    # try finding path by issue
    url = issue_url(params)
    
    # cache then grep issue page
    doc, referer_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true) if url
    lowest = 15
    if doc
      doc.search("td.small a").each do |a|
        if inner_text = a.inner_text
          term1 = a.inner_text.downcase
          term2 = article.title.downcase
          diff = diff_string(term1, term2)
          if diff < lowest
            lowest = diff
            puts "\nFound possible title match #{diff}\n"
            if (table = a.parent.parent.parent.children)
              table.search("a").each do |a|
                path = a['href'] if a['href'] =~ /http:\/\/pdf.medrang.co.kr\/Aod\/[\d]{3}\/Aod[\d]{3}-[\d]{2}-[\d]{2}.pdf/
              end
            end
          end
        end
      end
    end
    path
  end
  
end