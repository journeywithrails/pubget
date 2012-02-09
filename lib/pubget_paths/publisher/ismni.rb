class Publisher::ISMNI < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    "http://www.ismni.org/jmni/previousissues/v#{article.volume}i#{article.issue}.htm"
  end

  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    # Follow the linkout
    path = nil
    get_linkouts(article).each do |url|
      path = url if url =~ /pdf$/i
    end
    path
  end
end