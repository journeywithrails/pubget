class Publisher::Pier < Publisher::Metapress
  
  def info
    update_source("Pier", nil, issn, nil, title, nil, nil, nil, count, uncertain_title=true, pdf_back=nil, pdf_start, pdf_end, secondary_source=true, certain_date=true)
  end

end