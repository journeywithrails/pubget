class Publisher::Thieme < Publisher::Base
  
  def issue_url(params= {})
    article = params[:article]
    journal = article.journal
    
    if params[:inrequest]
      return journal.base_url
    else
      journal_code = journal.base_url.match(/\/ejournals\/toc\/([a-z]+)/)[1]

      # NOTE: This is really odd, but we must *first* access the journal's
      #       homepage (or perhaps any page on thieme-connect.com?) before it
      #       will allow us to access the JSON that contains the "issue codes"
      #       that we need...  !!!
      agent = HackedBrowser.new(use_cache=false)
      doc = agent.get(journal.base_url)

      json = agent.get("http://www.thieme-connect.com/ejournals/json/" +
        "issues?shortname=#{journal_code}&" +
        "year=#{article.article_date.year}").content
      lines = json.strip.split("\n")[1..-2].reject {|line| line.strip == ""}
      issue_codes = Hash.new
      lines.each do |line|
        if m = line.match(/\["([0-9]+)", "([0-9]+)"/)        
          code, issue = m[1], m[2].to_i
          issue_codes[issue] = code
        end
      end
    
      if journal.base_url.blank? or article.issue.blank?
        return nil
      else
        return File.join(journal.base_url, issue_codes[article.issue.to_i])
      end
    end
  end
  
  def pdf_url(params={})
    article = params[:article]
    journal_code = article.journal.base_url.match(/\/ejournals\/toc\/([a-z]+)/)[1]
    doc, redirect_url = CachedWebPage.get_cached_doc(:url=>issue_url(params), :details=>true, :expires_in=>1.months)
    uri = URI.parse(redirect_url)
    path = nil
    doc.search("a").each do |a|
      if a['href'] == "/ejournals/pdf/#{journal_code}/doi/#{article.get_doi}.pdf"
        path = uri.merge("/ejournals/pdf/#{journal_code}/doi/#{article.get_doi}.pdf").to_s
        break
      end
    end
    path
  end
end