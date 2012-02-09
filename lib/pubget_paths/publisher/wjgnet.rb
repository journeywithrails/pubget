class Publisher::Wjgnet < Publisher::Base

  def info
    update_journal("Wjgnet", nil, "1007-9327", nil, "World Journal of Gastroenterology", nil, "http://www.wjgnet.com/1007-9327/current.htm",
                   true, 1)
  end

  def pdf_url(params={})
    article = params[:article]

    path = "http://www.wjgnet.com/1007-9327/#{article.volume}/#{article.first_page}.pdf"
    path
  end
end