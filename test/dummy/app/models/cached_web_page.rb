class CachedWebPage
  # Hadoop HBase Cache of the Web

  @client = nil
  @last_uri
  @@last_agent = nil
  @@hbase_up = false
  @@hbase_last_tested = false
  
  def initialize
    @@hbase_up = false
    unless File.exists?("#{PUBLIC_BASE}/cachedweb/")
      `mkdir -p #{PUBLIC_BASE}/cachedweb/`
    end
  end

  def set_agent(agent)
    @agent = agent
  end
  
  def set_base_url= (a_url)
    @last_uri = URI.parse(a_url)
  end
  
  @@ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

  def self.get_cached_xml(params, slp=1, force=false, use_tor = false)
    CachedWebPage.new.get_cached_xml(params, slp, force, use_tor)
  end

  def get_cached_xml(params, slp=1, force=false, use_tor = false)
    if params.is_a?(Hash) and params[:details]
      text, redirected_to = get_cached_url(params, slp, force, use_tor)
      text = text.gsub(/\xA0/," ")
      [Nokogiri::XML(@@ic.iconv(text)), redirected_to]
    else
      Nokogiri::XML(@@ic.iconv(get_cached_url(params, slp, force, use_tor)))
    end
  end
  
  def self.get_cached_doc(params, slp=1, force=false, use_tor = false)
    CachedWebPage.new.get_cached_doc(params, slp, force, use_tor)
  end

  def get_cached_doc(params, slp=1, force=false, use_tor = false)
    if params.is_a?(Hash) and params[:details]
      text, redirected_to = get_cached_url(params, slp, force, use_tor)
      text = text.gsub(/\xA0/," ") if text.present?
      [Nokogiri::HTML(@@ic.iconv(text)), redirected_to]
    else
      Nokogiri::HTML(@@ic.iconv(get_cached_url(params, slp, force, use_tor)))
    end
  end
  
  def self.get_cached_url(params, slp=1, force=false, use_tor = false)
    CachedWebPage.new.get_cached_url(params, slp, force, use_tor)
  end
  
  def get_cached_page(url, force=false, options={})
    # xxx: this function needs work to come into like with HackedBrowser, esp. regarding the options hash. We probably don't do url queries 
    # consistently.
    if url.is_a?(Hash)
      options.merge!(url)
    else
      options[:url] = url
    end
    
    options[:force] = force unless options[:force]
    options[:details] = true
    
    headers = {}
    
    text, redirect_url, headers = self.get_cached_url(options)
    #puts "got text of length #{text.length}"
    #puts "got headers #{headers.inspect}"
    begin
      return WWW::Mechanize::Page.new(URI.parse(redirect_url), headers, text, "200")
    rescue WWW::Mechanize::ContentTypeError
      return WWW::Mechanize::File.new(URI.parse(redirect_url), headers, text, "200")
    end
  end
  
  def self.get_cached_page(params, force=false)
    CachedWebPage.new.get_cached_page(params, force)
  end

  def get_cached_url(params, slp=1, force=false, use_tor = false)
    
    #puts "fetching cached url: #{params.inspect}"
    
    if Thread.current['insearch']
      unless params and params.to_s =~ /\.ncbi\.nlm\.nih\.gov|crossref\.org/
        begin
          throw "Should not get inside web request" if (ENV["RAILS_ENV"] == 'production')
        rescue
          SystemNotifier.deliver_script_error("CachedWebPage.get_cached_url: Error #{$!}", "Trying to get: #{params.inspect}\n\n#{$!.backtrace.join('\n')}")
        end
      end
    end
    
    # backward compatible - convert string params into hash
    if params.is_a? String
      params = {:url=>params, :slp=>slp, :force=>force}
    end    
    a_url = params[:url]
    slp ||= params[:slp]||1
    force ||= params[:force] ? true : false
    grep = params[:grep]
    details = params[:details] ? true : false
    cache_only = params[:cache_only] ? true : false
    use_tor ||= params[:use_tor] ? true : false
    #use_pigeon = params[:use_pigeon] ? true : false
    #pigeon_host = params[:pigeon_host] ? params[:pigeon_host] : Pigeonizer::PUBGET_HOST
    use_pigeon = false
    referer = params[:referer]
    user_agent = params[:user_agent]||"FAST-WebCrawler/3.x Multimedia"
    success_codes = [] 
    success_codes += params[:codes].map {|c| c} if params[:codes]
    expires_in = params[:expires_in] || nil
    begin
      unless a_url =~ /^http/i
        @last_uri = @last_uri.merge(a_url)
        a_url = @last_uri.to_s
      end
      
      # URL is the key
      key = "#{a_url}"
      
      # Try to get it from the cache unless we try to force it
      if not force
        
        begin
          #puts "trying to get URL from cache"
          return get_cache(:key=>key, :details=>details, :expires_in=>expires_in)          
        rescue
          #puts "No cache found #{$!} - need to get #{a_url}"
          @skip_cache = true if $!.to_s =~ /execution expired/
          force = true # need to explicitly set this so we overwrite old cache rows
        end
        
      else
        #puts "Forcing get on #{a_url}"
      end
      
      # Create an agent if needed
      unless @agent
        if @@last_agent.present?
          @agent = @@last_agent
        else
          @agent = HackedBrowser.new(:agent => "Windows IE 7")
          @@last_agent = @agent
        end
      end  
      @agent.user_agent = params[:user_agent] if params[:user_agent]
      
      #done in hacked browser 
      #sleep slp if slp
      page = nil
      redirect_url = nil
      headers = nil
      @start_time = Time.now
      begin
        success_codes += ["403"] if grep == "jstor"
        page = @agent.get(:url=>a_url)
        content = page.body
        redirect_url = page.uri.to_s
        headers = page.header
# =======
#         if grep == "jstor"
#           content = `curl -L "#{a_url}" -c cookie.txt`
#           redirect_url = a_url
#           headers = {}
#         else
#           page = @agent.get(:url=>a_url, :use_tor=>use_tor, :use_pigeon=>use_pigeon, :referer=>referer)
#           content = page.body
#           redirect_url = page.uri.to_s
#           headers = page.header
#         end
# >>>>>>> .r10142
      rescue Timeout::Error
        puts "Following error occurred when trying to get URL #{a_url}: #{$!}"
        sleep 3
        page = @agent.get(:url=>a_url)
        content = page.body
        redirect_url = page.uri.to_s
        headers = page.header
      rescue
        puts "Following error occurred when trying to get URL #{a_url}: #{$!}"
        puts "in cached_web error handler"
        sleep 3
        page = @agent.get(:url=>a_url)
        content = page.body
        redirect_url = page.uri.to_s
        headers = page.header
      end
      puts "Getting took: #{Time.now - @start_time} on #{a_url}"
      if not @skip_cache     
        set_cache(:key=>key, :content=>content, :grep=> grep, :redirect_url=>redirect_url)
      end
      if details
        [content, redirect_url, headers]
      else
        content
      end
      
    rescue 
      puts "Following error occurred when trying to get URL #{a_url}: #{$!}"
      puts $!.backtrace
      if a_url.present?
        @client.create_row('cached_web_pages', key, Time.now.to_i, {:name => 'http:data', :value => "pubgetcacheerror occurred when trying to get URL #{a_url}: #{$!}", :grep=>grep}) if @client
        puts $!.backtrace
        ""
      end
    end
  end
  
  def self.set_cache(params)
    CachedWebPage.new.set_cache(params)
  end

  
  def self.get_cache(params)
    CachedWebPage.new.get_cache(params)
  end
  
  def self.fetch_cache(params)
    CachedWebPage.new.fetch_cache(params)
  end
  
  def fetch_cache(params)
    ret_val = nil
    begin
      ret_val = get_cache(params.merge(:skip_marshal=>false)) unless params[:force]
    rescue
      #puts "didn't find data in cache: #{$!}"
    end
    unless ret_val
      ret_val = yield
      set_cache(:key=>params[:key], :content=>ret_val, :skip_marshal=>false)
    end
    
    return ret_val
  end  
  
  def set_cache(params)
    set_file_cache(params)
  end
  
  def get_cache(params)
    get_file_cache(params)
  end
  
  def escape_key(key)
    if key.size > 140
      Digest::MD5.hexdigest(key)
    else
      key.gsub(/[^a-z0-9]/i,"_")
    end
  end
  
  def set_file_cache(params)
    key = escape_key(params[:key])
    content = params[:content]
    redirect_url = params[:redirect_url]
    
    h = {:content => content, :redirect_url=>redirect_url}
    
    
    path = "#{PUBLIC_BASE}/cachedweb/#{key}"
    #puts "Saving file to #{path}"
    File.open(path, 'w') do |out|
       YAML.dump(h, out)
    end
    `chmod 777 #{path}` unless is_windows?
  end
  
  def get_file_cache(params)
    key = escape_key(params[:key])
    details = params[:details]
    expires_in = params[:expires_in]
    
    timestamp = nil
    
    path = "#{PUBLIC_BASE}/cachedweb/#{key}"
    File.ctime(path)
    
    if expires_in and timestamp.nil?
      #puts "There is no timestamp, force a get of this URL so we can add a timestamp"
      throw "There is no timestamp, force a get of this URL so we can add a timestamp"
    end
    
    if expires_in and timestamp and timestamp < (Time.now - expires_in)
      #puts "Cache is older than desired, saved on #{timestamp}"
      throw "Cache is older than desired, saved on #{timestamp}"
    end
    
    h = YAML::load_file(path)
    content = h[:content]
    redirect_url = h[:redirect_url]
    if details
      [content, redirect_url, nil]
    else
      content
    end
  end  

end