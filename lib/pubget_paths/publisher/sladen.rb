class Publisher::Sladen < Publisher::Base
  def pdf_url(params)
    article = params[:article]
    url = guess_url(article)

    url
  end

  def guess_url(article)
    year = article.year.to_i
    volume = article.volume.to_i
    year = 1993 + volume if year.zero? and not volume.zero?
    return nil if year.zero?

    month = Time.parse(article.dp || artcle.article_date).strftime('%B')
    abbrev = article.journal.title_abbreviation.scan(/([A-Z])/).join

    "http://www.henryfordconnect.com/documents/Sladen%20Library/#{abbrev}-#{month}#{year}.pdf"
  end
end