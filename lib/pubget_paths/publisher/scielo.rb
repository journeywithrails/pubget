class Publisher::Scielo < Publisher::Base
  attr_accessor :article

  def pdf_url(params)
    self.article = params[:article]
    url = search_by_doi(article.doi || article.get_doi)
    url = search_by_title unless url

    url
  end

  def search_by_doi(doi)
    return nil unless doi

    article_url = join_url("/scielo.php?script=sci_arttext&pid=#{doi.gsub(/^.*\//, '')}&lng=en&nrm=iso")
    article_doc = CachedWebPage.get_cached_doc(:url => article_url, :grep => 'scielo')
    pdf_link = article_doc.at("div#toolBox > div.box > ul > li > a")

    if pdf_link and pdf_link['onclick'].scan(/^.*'(http:\/\/.*)\s'.*/)
      redirect_url = join_url(pdf_link['onclick'].match(/^.*'(http:.*)\s'.*/)[1])
      redirect_doc = CachedWebPage.get_cached_doc(:url => redirect_url, :grep => 'scielo')
      meta_tag = redirect_doc.at("meta[@name='added'][@http-equiv='refresh']")

      if meta_tag and meta_tag['content'].scan(/^.*(http:.*)$/)
        meta_tag['content'].match(/(http:.*\.pdf)/)[1]
      end
    end
  end

  def search_by_title
    title = article.title.size > 50 ?
      raze(article.title)[/\w[\w\s]{40}[\w]*/] :
      raze(article.title)[/\w[\w\s]{15}[\w]*/]
    aissn = article.journal.issn || ''

    search_url = join_url(URI.encode("/cgi-bin/wxis.exe/iah/?exprSearch=#{title}&limit=#{aissn}&IsisScript=iah/iah.xis&lang=i&base=article^dlibrary&nextAction=search&form=F&hits=20&conectSearch=and"))

    results_doc = CachedWebPage.get_cached_doc(:url => search_url, :grep => 'scielo')
    results = results_doc.search("form > center")

    atitle = raze(article.title)
    avolume = "vol.#{article.volume}, no.#{article.issue},"
    avolume_expr = /vol\.\d+,\sno\.\d+,/
    match = nil

    results.each do |result|
      result_content = result.at("table > tr > td[@width='485'] > table > tr")
      next unless result_content

      title = raze(result_content.at('font.isoref > font.negrito').render_to_plain_text)
      volume = result_content.at('font.isoref > i').next_sibling

      if volume
        volume_plain = volume.render_to_plain_text

        if volume_plain.scan(avolume_expr)
          volume = volume_plain.match(avolume_expr)[0]
        end
      end

      if atitle == title or (volume and avolume == volume)
        match = result_content.at("div[@align='left'] a")
        break
      end
    end

    search_by_doi(match['href'].match(/pid=([^\&]+).*/)[1]) if match and match['href']
  end

  def join_url(part)
    URI.parse(base_url).merge(part).to_s
  end

  def base_url
    return "http://www.scielo.com/" unless article.country

    main_page = CachedWebPage.get_cached_doc(:url => "http://www.scielo.org/php/index.php?lang=en", :grep => 'scielo')
    country = main_page.at("ul#countries > li > a[text()='#{article.country}']")
    return country['href'].gsub(/\?.*$/, '') if country

    # If country url is not present on scielo.org main page:
    case article.country
      when "Switzerland"
        "http://www.scielosp.org/"
    end
  end
end
