class HackedBrowser < WWW::Mechanize
  def initialize(options={})
    super()
    if options[:agent]
      begin
        self.user_agent = options[:agent]
      rescue Exception
        self.user_agent_alias = options[:agent]
      end
    else
      self.user_agent_alias = "Windows IE 7"
    end
  end
end 
class HackedBrowser < WWW::Mechanize
  def initialize(options={})
    super()
    if options[:agent]
      begin
        self.user_agent = options[:agent]
      rescue Exception
        self.user_agent_alias = options[:agent]
      end
    else
      self.user_agent_alias = "Windows IE 7"
    end
  end
end