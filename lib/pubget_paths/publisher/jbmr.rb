class Publisher::JBMR < Publisher::Base

  def issue_url(params={})
    article = params[:article]
    v, i = 0, 0

    unless issue.blank?
      v, i = article.volume, article.issue
    end

    "http://www.jbmronline.org/toc/jbmr/#{v}/#{i}"
  end

  def pdf_url(params={})
    article = params[:article]
    return article.get_doi ? using_doi(article) : without_doi(article, params)
  end

  private

  def using_doi article
    "http://onlinelibrary.wiley.com/doi/#{article.get_doi}/pdf"
  end

  def without_doi article, params
    params[:use_pigeon] ||= false

    path = nil
    source = CachedWebPage.get_cached_url(:use_pigeon=>params[:use_pigeon], :url=>issue_url(params), :slp=>1, :grep=>'jbmr')
    doc = parse_html(source)
    lowest = 10 #get at least 10 but get the lowest
    doc.search("table tr").each do |tr|
      diff = 11
      begin

        term1 = tr.at("div.art_meta").render_to_plain_text.downcase if tr.at("div.art_meta")
        term1 = tr.at("strong").render_to_plain_text.downcase unless term1
        term2 = article.title.downcase
        diff = diff_string(term1, term2)
      rescue
      end
      if diff < lowest
        lowest = diff
        tr.search("a").each do |a|
          path = "http://www.jbmronline.org#{a['href']}" if a.render_to_plain_text =~ /PDF/
        end
        tr.parent.search("a").each do |a|
          path = "http://www.jbmronline.org#{a['href']}" if a.render_to_plain_text =~ /PDF/
        end

      end
    end
    path
  end

end
