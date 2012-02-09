class Publisher::JNS < Publisher::AllenPress
  
  def issue_url(params)
    article = params[:article]
    "#{article.journal.base_url.gsub('loi', 'toc')}/#{article.volume}/#{article.issue}"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :slp=>1, :grep=>'jns')
    doc = parse_html(source)
    lowest = 10 #get at least 10 but get the lowest
    path = nil
    if article.get_doi
      return "http://thejns.org/doi/pdf/#{article.get_doi}"
    end
  end  
end