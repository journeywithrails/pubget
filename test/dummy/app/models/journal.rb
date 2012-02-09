class Journal
  
  def self.find_by_title_or_alias(title)
    j = Journal.new
    url = "client=grep&title_or_alias=#{title}"
    hash = Digest::MD5.hexdigest(CGI::escape(url) + GREP_SALT)
    url_send = "http://pubget.com/developer/get_journal?client=grep&title_or_alias=#{title}&hash=#{hash}"
    journal_mech = CachedWebPage.get_cached_url(url_send)
    journal_json = journal_mech
    journal_hash = JSON.parse(journal_json)
    j.values = journal_hash
    j
  end
  
  def self.find_by_issn(issn)
    j = Journal.new
    url = "client=grep&issn=#{issn}"
    hash = Digest::MD5.hexdigest(CGI::escape(url) + GREP_SALT)
    url_send = "http://pubget.com/developer/get_journal?client=grep&issn=#{issn}&hash=#{hash}"
    journal_mech = CachedWebPage.get_cached_url(url_send)
    journal_json = journal_mech
    journal_hash = JSON.parse(journal_json)
    j.values = journal_hash
    j
  end
  
  def self.find_by_eissn(eissn)
    j = Journal.find_by_issn(eissn)
    j
  end
  
  def values=(_values)
    @values = _values
  end
  
  def values
    @values
  end

  def method_missing(method_id, *args)
    method_name = method_id.to_s
    is_setter = /=$/ === method_name
    is_adder = /^add_/ === method_name
    
    if is_setter
      var_name = method_name[0...-1]
      expected_args = 1
    else
      var_name = method_name
      expected_args = 0
    end
    
    unless args.size == expected_args
      raise ArgumentError.new(
        "Wrong number of arguments (#{args.size} for #{expected_args})")
    end
    
    if is_setter
      @values[var_name] = args[0]
    else
      @values[var_name]
    end
  end

  def primary_issn
    if self.issn
      self.issn
    elsif self.eissn
      self.eissn
    else
      # Probably won't happen, because it's not possible
      # to instantiate a journal without an issn
      nil      
    end
  end
  
  def journal_host
    uri = URI.parse(self.base_url)
    "#{uri.scheme}://#{uri.host}"
  end

end
