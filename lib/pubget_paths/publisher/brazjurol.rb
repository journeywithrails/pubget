class Publisher::Brazjurol < Publisher::Base
  def pdf_url(params)
    url = nil
    article = params[:article]
    period, url = guess_url_or_period(article)

    if not url and period
      # another case, happens when we can not guess url by author name or
      # because of missed first/last page numbers

      # puts 'No guess worked, searching by title'
      # articles_doc = CachedWebPage.get_cached_doc(:url => join_url(period), :grep => 'brazjurol')
      # probably not needed yet
    end

    url
  end

  def guess_url_or_period(article)
    year = article.year.to_i
    issue = article.issue.to_i

    return nil if not year or not issue

    period = nil

    period =
      case issue
        when 1
          "janeiro"
        when 2
          "abril"
        when 3
          "maio"
        when 4
          "julho"
        when 5
          "tudo3"
        when 6
          "novembro"
      end if year == 2000

    period =
      case issue
        when 1
          "janeiro"
        when 2
          "marco"
        when 3
          "maio"
        when 4
          "julho"
        when 5
          "outubro"
        when 6
          "dezembro"
      end if year == 2001

    period =
      case issue
        when 1
          "janeiro"
        when 2
          "marco"
      end if year == 2002 and issue < 3

    period =
      case issue
        when 1
          "january_february"
        when 2
          "march_april"
        when 3
          "may_june"
        when 4
          "july_august"
        when 5
          "september_october"
        when 6
          "november_december"
      end unless period

    period = (year == 2000 ? period : "#{period}_#{year}")
    full_period = "#{period}.asp"

    authors = article.abbrev_authors
    first_page = article.first_page
    last_page = article.last_page

    return full_period, nil if authors.empty? or not first_page or not last_page

    articles_doc = CachedWebPage.get_cached_doc(:url => join_url(full_period), :grep => 'brazjurol')

    authors.each do |author|
      author = author.match(/(\w+)\s|$/)[1]
      url = "#{period}/#{author}_#{first_page}_#{last_page}.pdf"
      return full_period, join_url(url) if articles_doc.at("a[@href='#{url}']")
    end
  end

  def join_url(part)
    URI.parse('http://www.brazjurol.com.br/').merge(part).to_s
  end
end
