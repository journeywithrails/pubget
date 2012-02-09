class Publisher::Karger < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    article.journal.base_url + "&searchParm=#{article.article_date.year}"
  end

  def pdf_url(params={})
    article = params[:article]

    path = guess_url(article)
    path = search_by_title(article) unless path

    unless path
      if article.get_doi(params)
        url = "http://dx.doi.org/#{article.get_doi(params)}"
        doc, redirect_url = CachedWebPage.get_cached_doc(:url=>url, :details=>true)
        uri = URI.parse(redirect_url)
        doc.search("td a").each do |a|
          path = uri.merge(a['href']).to_s if a.render_to_plain_text =~ /PDF/
        end
      end
    end

    path
  end

  def guess_url(article)
    pii = article.pii || (article.doi || article.get_doi)
    return nil unless pii

    pii.gsub!(/^.*\//, '')
    pii.gsub!(/^0*/, '')

    articles_url = find_isue_url(article)
    return nil unless articles_url

    articles_page = CachedWebPage.get_cached_doc(:url => articles_url, :grep => 'karger')
    guess = articles_url.gsub(/Aktion=Ausgabe/, "Aktion=ShowPDF&ArtikelNr=#{pii}") + "&filename=#{pii}.pdf"

    return guess if articles_page.at("a[@href='#{guess}']")
    nil
  end

  def search_by_title(article)
    #article_url = find_isue_url(article)
    nil
  end

  def find_isue_url(article)
    year = article.year
    volume = article.volume
    issue = article.issue
    return nil if year.blank? or volume.blank? or issue.blank?

    journal_url = find_journal_url(article)
    return unless journal_url

    journal_url = "#{journal_url}&searchParm=#{year}"
    journal_page = CachedWebPage.get_cached_doc(:url => journal_url, :grep => 'karger')

    results = journal_page.search("table#Table2 > tr")
    aissue_str = "No. #{issue}"

    results.each do |result|
      if volume_td = result.at("td.normal")
        volume_str = volume_td.next_sibling.next_sibling.render_to_plain_text.strip
        next unless volume == volume_str

        node = result

        while (node and node.next_sibling) do
          if issue_td = node.at("td.normal > a")
            issue_str = issue_td.render_to_plain_text.strip
            return issue_td['href'] if aissue_str == issue_str
          end

          node = node.respond_to?(:next_sibling) ? node.next_sibling : nil
        end
      end
    end
  end

  def find_journal_url(article)
    return nil unless article.journal.title

    journals_url = join_url("produkte.asp")
    journals_page = CachedWebPage.get_cached_doc(:url => journals_url, :grep => 'karger')

    journals = journals_page.search("table[@width='460'] > tr")
    jtitle = raze(article.journal.title)

    journals.each do |journal|
      if link = journal.at("td[@colspan='2'] > span > a.middle1")
        title = raze(link.render_to_plain_text)
        return link['href'] if jtitle == title
      end
    end

    max_diff = 10
    match = nil

    journals.each do |journal|
      if link = journal.at("td[@colspan='2'] > span > a.middle1")
        title = raze(link.render_to_plain_text)
        diff = String.diff_string(jtitle, title)

        if diff < max_diff
          max_diff = diff
          match = link['href']
        end
      end
    end

    match
  end

  def join_url(part)
    URI.parse("http://content.karger.com/ProdukteDB/").merge(part).to_s
  end
end