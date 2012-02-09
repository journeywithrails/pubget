class Publisher::Scitation < Publisher::Base
  
  # The scitation_open URL is shared among the two publishers aip and aps
  def openurl(params={})
    article = params[:article]
    key = "#{article.journal.base_url.split("?").last.gsub('/htmltoc','')}"
    "http://link.aip.org/link/?#{key}/#{article.volume}/#{article.start_page}/html"
  end

end