class Publisher::Landes < Publisher::Base
  
  def issue_url(params={})
    article = params[:article]
    "#{article.journal.base_url}/toc/#{article.volume}/#{article.issue}"
  end
  
  def pdf_url(params={})
    article = params[:article]
    params[:use_pigeon] ||= false
    key = Hash.new
    key['1547-6286'] = "RNA"
    key['1933-6896'] = "PRION"
    key['1559-2316'] = "PSB"
    key['1942-0900'] = "OM"
    key['1547-6278'] = "ORG"
    key['1554-8600'] = "HV"
    key['1933-6934'] = "FLY"
    key['1559-2294'] = "EPI"
    key['1942-0889'] = "CIB"
    key['1000-467X'] = "CJC"
    key['1933-6950'] = "CHAN"
    key['1538-4101'] = "CC"
    key['1933-6918'] = "CAM"
    key['1538-4047'] = "CBT"
    key['1554-8627'] = "AUTO"
    key['1554-8635'] = "AUTO"
    
    name_key = article.first_author[0].split(' ').first
    name_key = name_key.gsub('-','') if name_key =~ /-/
    name_key = Iconv.iconv('ascii//translit', 'utf-8', name_key).to_s
    name_key = name_key.gsub(/-|~|'/,'') if name_key =~ /-|~|''/
    
    "#{article.journal.base_url}/#{name_key}#{key[article.journal.primary_issn]}#{article.volume}-#{article.issue}.pdf"
  end
end