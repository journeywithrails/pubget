class Publisher::Nature < Publisher::Base

  def openurl(params={})
    article = params[:article]
    if article.get_doi(params)
      "http://www.nature.com/doifinder/#{article.get_doi(params)}"
    else
      nil
    end
  end

  def searchurl(params={})
    article = params[:article]
    "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=#{CGI.escape(article.title.gsub('&', ''))}&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=&sp-p-3=all&sp-q-4=#{article.volume}&sp-q-5=#{article.issue}&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
  end

  def issue_url(params={})
    article = params[:article]
    volume, issue = article.volume, article.issue
    journal_url = article.journal.base_url
    if volume =~ /pt/i
      nissue = volume.split(" ").last.to_i
      nvolume = volume.split(" ").first
      return File.join(journal_url, "journal/v#{nvolume}/n#{nissue}/")
    elsif volume =~ /suppl/i
      #return File.join(journal_url, "archive/index.html")
      return nil
    elsif volume =~ /spec no$/i
      return nil
    elsif (issue =~ /suppl/i) || (issue =~ /spec no$/i)
      nissue = issue.split(" ").first.to_i
      nvolume = volume.split(" ").first
      return File.join(journal_url, "journal/v#{nvolume}/n#{nissue}s/")
    elsif volume.empty? and issue.empty?
      return nil
    else
      nissue = issue
      nissue = issue.split(" ").last.to_i if issue =~ /pt/i
      return File.join(journal_url, "journal/v#{volume}/n#{nissue}/")
    end
  end

  def pdf_url(params={})
    article = params[:article]
    doi = article.get_doi(params)
    params[:use_pigeon] ||= false
    overview_page, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://dx.doi.org/#{article.get_doi(:force=>true)}", :grep=>'nature', :details=>true, :expires_in=>2.days)

    if pdf_link = overview_page.at("a[text()*='Download PDF']")
      pdf_url = pdf_link ? "#{URI.parse(article.journal_issue_url).merge(pdf_link['href'])}" : nil
      return pdf_url if pdf_url
    end

    if pdf_link = overview_page.at("a[text()*='PDF Format']")
      pdf_url = pdf_link ? "#{URI.parse(article.journal_issue_url).merge(pdf_link['href'])}" : nil
      return pdf_url if pdf_url
    end

    article_issue_url = self.issue_url(params)
    if not article_issue_url
      if doi and url_match = redirect_url.match(/https?:\/\/(?:www)?[\w\.\/]+\/journal\/v\d+\/n\d+\/full\/#{doi.gsub(/^.*\//, '')}\.html$/) and url_match[0]
        return url_match[0].gsub(/\/full\//, '/pdf/').gsub(/.html$/, '.pdf')
      end
    end

    if article.volume.blank? and article.issue.blank? and article.journal_issue_url
      if toc = overview_page.at("a[text()='Table of Contents']")
        article_issue_url = "#{URI.parse(article.journal_issue_url).merge(toc['href'])}"
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=>article_issue_url, :grep=>'nature', :details=>true, :expires_in => 5.days)
      end
    end

    if article_issue_url
      doc, redirect_url = CachedWebPage.get_cached_doc(:url=>article_issue_url, :grep=>'nature', :details=>true)
      uri = URI.parse(redirect_url)
      path = nil
    end

    if doi and doc
      doc.search("a").each do |a|
        if a.inner_text =~ /PDF/
          if part = doi.split("/").last
            if a['href'] =~ /#{part}\.pdf/
              path = uri.merge(a['href']).to_s
            end
          end
        end
      end
    end

    if doc and not path
      nodes = doc.search("td > font > b").map do |b|
        [b, b.parent.parent]
      end
      if nodes.length == 0
        nodes = doc.search("td").map do |td|
          outer = td
          title_span = td.at("span.articletitle")
          unless title_span
            if td['class'] == "tocatl"
              # When there is no span and its a load of tr and td elements
              title_span = td
              outer = td.parent.next_sibling().next_sibling().
                next_sibling().next_sibling()
            end
          end
          [title_span, outer]
        end
      end
      if nodes.length == 0
        nodes = doc.search("div.container").map do |div|
          outer = div
          title_span = div.at("h4")
          [title_span, outer]
        end
      end
      articles = nodes.map do |n|
        if n[0]
          title = n[0].render_to_plain_text
          pdf_link = nil
          n[1].search("a").each do |a|
            if a.inner_text =~ /PDF/
              pdf_link = a
            end
          end
          u = pdf_link ? uri.merge(pdf_link['href']).to_s : nil
          {'title' => title, 'pdf_url' => u}
        end
      end
      articles.compact!
      path = article.find_pdf_url_from_title(articles)
    end

    if path.blank? and doc
      lowest = 10
      doc.search("h4").each do |h4|
        if span = h4.at("span.page")
          term1 = article.title
          term2 = h4.inner_text.gsub(span.inner_text, '').gsub(/ - $/, '')
          diff = diff_string(term1, term2)
          if diff < lowest
            #puts "Found possible title match #{diff}"
            lowest = diff
            h4.parent.search("a").each do |a|
              if a.inner_text =~ /PDF/
                path = uri.merge(a['href']).to_s
              end
            end
          end
        end
      end
    end

    if path.blank? and (doi = article.get_doi(params))
      adoc, redirect_url = CachedWebPage.get_cached_doc(:url=>"http://www.nature.com/doifinder/#{doi}", :grep=>'nature', :details=>true)
      # Could be list of matches (take the best)

      if (adoc.at("title").inner_text =~ /Citation$/) and (adoc.inner_text =~ /This article appears in/)
        # Lookup next link
        adoc.search("a.articletext").each do |alink|
          nadoc, redirect_url = CachedWebPage.get_cached_doc(:url=>uri.merge(alink['href']).to_s, :grep=>'nature', :details=>true)
          if nadoc.search("li.pdf a").size > 0
            adoc = nadoc
            break
          elsif nadoc.search("li.download-pdf a").size > 0
            adoc = nadoc
          end
        end
      end

      # or just the match
      (adoc.search("li.pdf a") + adoc.search("li.download a") + adoc.search("div.article a")).each do |a|
        if a.inner_text =~ /PDF Format|Download PDF|Download a PDF of this article/
          path = uri.merge(a['href']).to_s
        end
      end

      if bookmark_link = adoc.at("a[text()='Bookmark in Connotea']")
        return bookmark_link['href'].gsub(/^.*uri=/, '').gsub(/\/full\//, '/pdf/').gsub(/.html$/, '.pdf')
      end

      if path.blank? and toc = adoc.at("a[text()='Table of Contents']") and article.title
        overview_page, redirect_url = CachedWebPage.get_cached_doc(:url => "http://www.nature.com/#{toc['href']}", :expires_in => 2.days)
        collection = overview_page.search('div#content > div.container > div')
        max_diff = 10
        match = nil

        collection.search('h4').each_with_index do |h4, index|
          diff = String.diff_string(article.title, h4.text)
          if diff <= max_diff
            max_diff = diff
            match = collection[index]
          end
        end

        if match
          match.search('a').each do |a|
            return File.join('http://www.nature.com/', a['href']) if a.text =~ /PDF/
          end
        end
      end

      if path.blank?
        adoc.search("li.export-citation a").each do |a|
          if a.inner_text == "Export citation"
            path = uri.merge(a['href']).to_s.gsub("ris", "pdf")
          end
        end
      end
      if path.blank?
        adoc.search("li.download-pdf a").each do |a|
          if a.inner_text == "Download PDF"
            path = uri.merge(a['href']) if uri and a['href']
          end
        end
      end
      if path.blank?
        # Run brute force search
        search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=default&sp-q=#{doi}&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=&sp-p-3=all&sp-q-4=&sp-q-5=&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
        path = try_search_url(uri, article, search_url)
      end
    end
    if path.blank?
      search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=#{CGI.escape(article.title.gsub('&', ''))}&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=&sp-p-3=all&sp-q-4=#{article.volume}&sp-q-5=#{article.issue}&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
      path = try_search_url(uri, article, search_url)
    end
    # Inteviews are stored in nature as just the name
    if path.blank? and (article.title.split(/[\.\sis]+interview(ed)? by/i).size > 1)
      title = article.title.split(/[\.\sis]+interview(ed)? by/i).first
      if title.length > 10
        search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=#{CGI.escape(title)}&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=&sp-p-3=all&sp-q-4=#{article.volume}&sp-q-5=#{article.issue}&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
        path = try_search_url(uri, article, search_url, title)
      end
    end
    if path.blank? and (article.title.split(/An interview with/i).size > 1)
      title = article.title.split(/An interview with/i).last
      if title.length > 10
        search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=#{CGI.escape(title)}&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=&sp-p-3=all&sp-q-4=#{article.volume}&sp-q-5=#{article.issue}&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
        path = try_search_url(uri, article, search_url, title)
      end
    end
    # Making the paper search
    if path.blank? and (article.title =~ /^making the paper/i)
      search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=making+the+paper%3A&sp-p-3=all&sp-q-4=#{article.volume}&sp-q-5=#{article.issue}&sp-q-6=&sp-q-10=&sp-q-11=&sp-q-12=&sp-start-month=&sp-start-year=&sp-end-month=&sp-end-year=&sp-date-range=0&sp-q-8=&sp-s=date_descending&sp-c=25"
      path = try_search_url(uri, article, search_url, "making the paper:")
    end
    # final wide year long search
    if path.blank?
      search_url = "http://www.nature.com/search/executeSearch?sp-advanced=true&include-collections=journals_nature%2Ccrawled_content&exclude-collections=journals_palgrave%2Clab_animal&sp-m=0&siteCode=nature&sp-q=&sp-p=all&sp-q-2=&sp-p-2=all&sp-q-3=#{CGI.escape(article.title.gsub('&', ''))}&sp-p-3=all&sp-q-4=&sp-q-5=&sp-q-6=&pub-date-mode=between&sp-start-month=01&sp-start-year=#{article.year}&sp-end-month=12&sp-end-year=#{article.year}&sp-q-8=&sp-s=date_descending&sp-c=25"
      path = try_search_url(uri, article, search_url)
    end

    unless path
      puts "no results found; searching URL by title"
      search_url_by_title(doc, article)
    end

    path
  end

  def search_url_by_title(doc, article)
    if doc.search("//a/text()='#{article.title}'")
      a = doc.at("a[text()='#{article.title}']")
      article.url = a['href'].index("http").nil? ?
        URI.parse(article.journal_issue_url).merge(a['href']) : a['href']
    end
  end

  def try_search_url(uri, article, search_url, title=nil)
    title ||= article.title
    path = nil
    adoc, redirect_url = CachedWebPage.get_cached_doc(:url=>search_url, :grep=>'nature', :details=>true)
    lowest = 15

    adoc.search("div#content li").each do |li|
      if li.at("h2")
        term1 = li.at("h2").render_to_plain_text.downcase
        term2 = title.downcase
        diff = diff_string(term1, term2)
        if diff < lowest
          li.search("a").each do |a|
            if a.inner_text == "PDF"
              path = uri.merge(a['href']).to_s
            end
          end
        end
      end
    end
    path
  end

end
