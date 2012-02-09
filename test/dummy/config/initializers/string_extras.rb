
# XXX: I don't understand why we want the string below to be "1.9".  I'm quite
#      certain that it could be any string, but I've kept it as the example
#      was, where I found it:
#      http://balpreetpankaj.com/blog/2008/12/31/ruby-187-stringchars-compatibility-problem-with-rails/
unless '1.9'.respond_to?(:force_encoding)
  String.class_eval do

    begin
      remove_method :chars
    rescue NameError
      # OK
    end

    define_method :mb_chars do
      ActiveSupport::Multibyte::Chars.new(self)
    end

  end
end

class String

  #partitions a string based on regex.  matches are included in results
  #ex. 'a b  c'.partition(/ +/) returns ['a', ' ', 'b', '  ', 'c']
  #ex. ' b '.partition(/ +/) returns [' ', 'b', ' ']
  def partition(regex)
    results = []
    s = StringScanner.new(self)
    last_pos = 0
    while(s.skip_until(regex))
      matched_size = s.matched_size
      pos = s.pos
      #add the non-delimiter string if it exists (it may not if the string starts with a delimiter)
      results << self[last_pos ... pos - matched_size] if last_pos < pos - matched_size
      #add the delimiter
      results << self[pos - matched_size ... pos]
      #update the last_pos to the current pos
      last_pos = pos
    end
    #add the last non-delimiter string if one exists after the last delimiter.  It would not have
    #been added since s.skip_until would have returned nil
    results << self[last_pos ... self.length] if last_pos < self.length
    results
  end
  
  def pgcamelize
    if self.length < 4
      self.upcase
    else
      self.camelize.gsub(" ",'')
    end
  end
  
  def upfirstchar
    self.gsub(/^([a-z])/) { $1.upcase }
  end

  def self.random_string(length = 6)
    string = ""
    chars = ("A".."Z").to_a
    length.times do
      string << chars[rand(chars.length - 1)]
    end
    return string
  end


  def ad_word_case
    avoid_words = ["a", "an", "the", "and", "but", "for", "nor", "or", "from", "on", "that", "if", "as", "at", "of"]
    self.downcase!
    parts = self.split(" ").map{|x| avoid_words.include?(x) ? x.downcase : x.capitalize}
    parts.first.capitalize!
    parts.last.capitalize!
    parts.join(" ")
  end
  
  def titlecase
     non_capitalized = %w{of etc and by the for on is at to but nor or a via}
     gsub(/\b[a-z]+/){ |w| non_capitalized.include?(w) ? w : w.capitalize  }.sub(/^[a-z]/){|l| l.upcase }.sub(/\b[a-z][^\s]*?$/){|l| l.capitalize }
  end
  
  def issn?
    if self =~ /^\d{4,4}\-[\dXx]{4,4}$/
      return true
    else
      return false
    end
  end
  
  def strip_tags( t = [] )
    # remove some HTML tags from string for easier processing as in date parsing
    tags = ["strong", "b"] + t
    s = self
    tags.each do |t|
      s = s.gsub(/<#{t}>/i,' ').gsub(/<\/#{t}>/i, ' ')
    end
    s.gsub(/\n|\r\n/,' ').gsub(/ {2,}/, ' ')
  end
  
  def self.diff_string(term1, term2, min=20)
    diff_len = (term1.size - term2.size).abs
    
    if diff_len > min
      return min
    else
      return Text::Levenshtein.distance(term1, term2)
    end
  end
  
  def self.max_len(text, len=10)
    if text && (text.size > len)
      "#{text[0...len]}..."
    else
      text
    end
  end
  
  def word_to_number
    words = %w{one two three four five six seven eight nine ten eleven twelve}
    begin
      words.index(self.downcase) + 1
    rescue Exception
      raise ArgumentError.new "#{self} is not a valid number. If this is in error, add it to /config/initializers/string_extras.rb#word_to_number"
    end
  end
  
  # NOTE: this function is a hack to work around lack of explicit encoding
  def jibberish?
    good  = self.scan(/[a-zA-Z0-9]/).length
    total = self.length.to_f
    
    # call it jibberish if the string is mostly made up of non-alphabet characters
    good/total < 0.50 ? true : false
  end
end
