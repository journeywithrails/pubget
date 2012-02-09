class Publisher::Muse < Publisher::Base
  def info
    url = "http://muse.jhu.edu/holdings?cid=all_2011&format=csv&shows=jname&shows=url&shows=is_online&shows=pname&shows=eissn&shows=pissn&shows=oclc&shows=first_issue&shows=last_issue&shows=archive_only&shows=coverage&shows=description"
  end
  
  def pdf_url(params={})
    nil
  end
end