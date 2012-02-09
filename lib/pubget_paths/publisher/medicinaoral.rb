class Publisher::Medicinaoral < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = guess_pdf_url(article)

    url
  end

  def guess_pdf_url(article)
    first_page = article.first_page.match(/\d+/)[0]
    return nil unless first_page

    issue_url, year, volume, issue = find_issue_url(article)
    return nil unless issue_url

    articles_doc = CachedWebPage.get_cached_doc(:url => issue_url, :grep => 'medicinaoral')

    guess =
      case year
        when 2004..2010
          join_url("/medoralfree01/v#{value}i#{issue}/medoralv#{value}i#{issue}p#{first_page}.pdf")
        else
          join_url("/pubmed/medoralv#{volume}_i#{issue}_p#{first_page}.pdf")
      end

    guess if articles_doc.at("a[@href='#{guess}']")
  end

  def find_issue_url(article)
    issue = article.issue.to_i
    return nil if issue.zero?

    year = article.year.to_i
    volume = article.volume.to_i
    year = volume + 1995 if volume and year.zero?
    volume = year - 1995 if year and volume.zero?
    return nil if year.zero? or volume.zero?

    prefix =
      case year
        when 2004
          'volut12004'
        when 2005..2010
          'medoral'
        else
          ''
      end

    suffix =
      case year
        when 2004-2010
          'htm'
        else
          'html'
      end

    return join_url("/#{year}/#{prefix}v#{volume}i#{issue}.#{suffix}"), year, volume, issue
  end

  def join_url(part)
    URI.parse('http://www.medicinaoral.com/').merge(part).to_s
  end
end