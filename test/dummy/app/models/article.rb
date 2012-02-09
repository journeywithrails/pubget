class Article

  def self.find_by_pmid(pmid)
    a = Article.new
    url = "client=grep&pmid=#{pmid}"
    hash = Digest::MD5.hexdigest(CGI::escape(url) + GREP_SALT)
    url_send = "http://pubget.com/developer/get_article?client=grep&pmid=#{pmid}&hash=#{hash}"

    puts "url send=============", url_send
    article_json = CachedWebPage.get_cached_url(url_send)
    article_hash = JSON.parse(article_json)

    #In case with Orthosupersite needed values stored under index 3
    index = article_hash.values[2].is_a?(Hash) ? 2 : 3

    #Should be 'new values'
    a.values = article_hash.values[index]
    a
  end

  def url=(url)
    @url = url
  end

  def url
    @url
  end
  
  def pdf_sources
    values['pdf_sources']||[]
  end
  
  def pdf_urls
    values['pdf_urls']||[]
  end
  # initialize internal pdf_map
  def init_pdf_map
    return nil if @pdf_map
    @pdf_map = Hash.new
    
    pdf_sources.each_index do |index|
      @pdf_map[pdf_sources[index]] = pdf_urls[index]
    end
    nil
  end
  private :init_pdf_map
  
  
  def add_pdf_url(publisher, url)
    init_pdf_map
    return if not publisher or publisher.chomp.blank?
    return if not url or url.chomp.blank?

    @pdf_map[publisher] = url;
  end
  
  def get_pdf_url(publisher)
    init_pdf_map
    url = @pdf_map[source]
  end

  def values=(_values)
    @values = _values
  end

  def values
    @values
  end

  def pmid
    if @values['pmid'].blank?
      raise NameError.new("'pmid' value is not generated until article is saved")
    else
      if @values['pmid'].class == Array
        @values['pmid'].each do |value|
          if value =~ /^[\d]{3,9}$/
            @primary_pmid = value
            return value
          end
        end
        @primary_pmid = @values['pmid'].first
        @values['pmid'].first
      else
        @primary_pmid = @values['pmid']
        @values['pmid']
      end
    end
  end

  def sort_title
    @values['sort_title']
  end

  def doi
    if @values['doi'].class == Array and @values['doi'].first.present?
      return @values['doi'].first
    elsif @values['doi'].class == String and @values['doi'].present?
      return @values['doi']
    end
  end

  def get_pagination_pieces
    if self.pagination.blank?
      []
    else

      pieces = self.pagination.split(";")
      if pieces and pieces[0]
        pieces[0].split("-")
      else
        [self.pagination]
      end

    end
  end

  def pagination_short
    return nil if self.pagination == nil
    pieces = get_pagination_pieces
    if pieces.length == 1
      return pieces[0]
    elsif pieces.length > 2
      #if pieces.length != 2 || pieces[0].length != pieces[1].length
      return self.pagination
    else
      x = 0
      x += 1 while pieces[0][x] == pieces[1][x]
      return pieces[0] + "-" + pieces[1][x..-1]
    end
  end

  def pagination_long(expanded=false)
    return nil if self.pagination.blank?
    return nil if self.pagination == "-"
    pieces = get_pagination_pieces
    if pieces.length == 1
      if expanded
        return "#{pieces[0]}-#{pieces[0]}"
      else
        return pieces[0]
      end
    elsif pieces[0] and pieces[1]
      trimmed_len = pieces[0].length - pieces[1].length
      return pieces[0] + "-" +
        (trimmed_len > 0 ? pieces[0][0..(trimmed_len - 1)] : "") + pieces[1]
    else
      return self.pagination
    end
  end

  def method_missing(method_id, *args)
    method_name = method_id.to_s
    allowed_article_methods = self.values.keys

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
      "Wrong number of arguments (#{args.size} for #{method_name} #{expected_args})")
    end

    if is_setter
      @values[var_name] = args[0]
    else
      @values[var_name]
    end
  end

  def journal
    # Try to find by issn
    if (not @journal) and self.issn
      self.issn.each do |issn|
        begin
          @journal = Journal.find_by_issn(issn)
        rescue Exception
        end
      end
    end

    # If that didn't work, try to find by eissn
    if (not @journal) and self.eissn
      self.eissn.each do |eissn|
        begin
          @journal = Journal.find_by_eissn(eissn)
        rescue Exception
        end
      end
    end
    @journal
  end

  def get_doi(params={})
    force = params[:force]
    if self.doi.present?
      return self.doi
    end
    if params[:inrequest]
      return nil
    end
    if self.doi.blank? and self.has_pmid?
      a_url = "#{PUBMED_HOST}/entrez/eutils/efetch.fcgi?db=pubmed" +
        "&#{PUBMED_ID_TAG}&retmode=xml&rettype=xml&id=#{pmid}"
      source = CachedWebPage.get_cached_url(a_url, 0, force)
      if doi_match = /<ELocationID EIdType="doi" ValidYN="Y">([\S]+)<\/ELocationID>/i.match(source)
        self.doi = doi_match[1]
      elsif doi_match = /<ArticleId IdType="doi">([\S]+)<\/ArticleId>/i.match(source)
        self.doi = doi_match[1]
      end
    end

    if self.doi.blank?
      query = CGI.escape "#{self.journal.primary_issn}|#{self.journal.title}|#{self.abbrev_authors.first}|#{self.volume}|#{self.issue}|#{self.start_page}|#{self.year}||#{self.pmid}|"
      doi_url = "http://doi.crossref.org/servlet/query?qdata=#{query}&usr=pubget&pwd=pubget1209"
      source, redirect_url = CachedWebPage.get_cached_url(:url=>doi_url, :details=>true)

      if source and source.split("|")[9]
        self.doi = source.split("|")[9].strip
      else
        puts "No DOI: #{source}"
      end
    end
    return self.doi
  end

  def get_doi_from_crossref
    query = CGI.escape "#{self.journal.primary_issn}|#{self.journal.title}|#{self.abbrev_authors.first}|#{self.volume}|#{self.issue}|#{self.start_page}|#{self.year}||#{self.pmid}|"
    doi_url = "http://doi.crossref.org/servlet/query?qdata=#{query}&usr=pubget&pwd=pubget1209"
    source, redirect_url = CachedWebPage.get_cached_url(:url=>doi_url, :details=>true)

    if source and source.split("|")[9]
      self.doi = source.split("|")[9].strip
    else
      puts "No DOI: #{source}"
    end
    self.doi
  end

  def journal_issue_url
   @pub_class.issue_url(:article => self)
  end

  def find_pdf_url_from_title(articles)
    # Article titles should be off by no more than 10 Levenshtein points...
    lowest_diff = 10
    url = nil
    matches = []
    articles.each do |values|
      next if values["title"].blank?
      this_title = values["title"].downcase
      desired_title = self.title.downcase
      #patterns = [/\|\s*pdf\s*\([0-9]+ kb\)/, /\[[a-z ]+\]/i, /^[a-z ]+:/i]
      patterns = [/\[[a-z ]+\]/i, /^[a-z ]+:/i]
      patterns.each do |p|
        t1 = p ? this_title.gsub(p, "").strip : this_title
        t2 = p ? desired_title.gsub(p, "").strip : desired_title
        #puts "Comparing '#{t1}' to '#{t2}'"
        diff = Text::Levenshtein.distance(t1, t2)
        #puts "    Diff: #{diff}"
        matches = [] if diff < lowest_diff
        if diff <= lowest_diff
          lowest_diff = diff
          matches << values
          break
        end
      end
    end
    if matches.length > 1
      puts "WARNING: Multiple articles had matching titles, so not sure " +
        "which one to use: #{matches.inspect}"
    end
    return matches.length == 1 ? matches.first['pdf_url'] : nil
  end

  def article_date
    if @article_date
      return @article_date
    else
      if date_matcher = /^([\d]{2,4})\-([\d]{2})\-([\d]{2})T/.match(self.values['article_date'])
        @article_date = Date.civil(date_matcher[1].to_i, date_matcher[2].to_i, date_matcher[3].to_i)
      else
        @article_date = nil
      end
    end
    @article_date
  end

  def calculate_pdf_url(pub_class)
    @pub_class = pub_class # Get publisher
    response = @pub_class.pdf_url(:article => self, :force => true)

    puts "Journal ISSN: #{self.journal.issn}. Article Path: #{response || self.url || 'not found'}\n\n"
    response
  end
end
