require 'nokogiri'
require 'htmlentities'


module Nokogiri

  class XML::Node

    @@ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    def content_at_xpath path
      node = self.at_xpath(path)
      if node
        node.content
      else
        nil
      end
    end    
    

    def content_at path
      node = self.at(path)
      if node
        node.content
      else
        nil
      end
    end

    def render_to_plain_text
      if self.blank?
        return ""
      elsif self.comment?
        return ""
      elsif self.text?
        # Turn strange space-like character into space, turn newlines and
        # carriage-returns into spaces, and convert any
        # sequences of multiple spaces into a single space.
        return self.to_s.gsub(/\r|\n/, " ").gsub("\xc2\xa0", " ").
          gsub(/\s{2,}/, " ")
      else
        inner_text = ""
        #self.each_child {|c| inner_text += c.render_to_plain_text}
        self.children.each {|c| inner_text += c.render_to_plain_text}
        name = self.element? ? self.name : ""
        text = case name.downcase
          when "div", "table", "h1", "h2", "h3", "h4", "h5", "h6":
            "\n" + inner_text.strip + "\n"
          when "tr", "br": "\n" + inner_text.strip
          when "li": "\n* " + inner_text.strip
          when "p", "ul": "\n\n" + inner_text.strip
          when "td": " " + inner_text.strip
          when "img": "" #self.attributes['alt'] ? self.attributes['alt'].value : ""
          else inner_text
        end
        text = HTMLEntities.new.decode(text.gsub(/&(nbsp|#xa0);/, " "))
        text.gsub(/[ \t]*\n[ \t]*/m, "\n")
        begin 
          return @@ic.iconv(text)
        rescue Iconv::InvalidCharacter
          return inner_text
        end
      end
    end
    
    def render_to_plain_text_p
      if self.comment?
        return ""
      elsif self.text?
        # Turn strange space-like character into space, turn newlines and
        # carriage-returns into spaces, and convert any
        # sequences of multiple spaces into a single space.
        return self.to_s.gsub(/\r|\n/, " ").gsub("\xc2\xa0", " ").
          gsub(/\s{2,}/, " ")
      else
        inner_text = ""
        #self.each_child {|c| inner_text += c.render_to_plain_text}
        self.children.each {|c| inner_text += c.render_to_plain_text}
        name = self.element? ? self.name : ""
        text = case name.downcase
          when "div", "table", "h1", "h2", "h3", "h4", "h5", "h6":
            "\n" + inner_text.strip + "\n"
          when "tr", "br": "\n" + inner_text.strip
          when "li": "\n* " + inner_text.strip
          when "ul": "\n\n" + inner_text.strip
          when "td": " " + inner_text.strip
          when "img": self.attributes['alt'] ? self.attributes['alt'].value : ""
          else inner_text
        end
        text = HTMLEntities.new.decode(text.gsub(/&(nbsp|#xa0);/, " "))
        text.gsub(/[ \t]*\n[ \t]*/m, "\n")
        begin
          return @@ic.iconv(text)  
        rescue Iconv::InvalidCharacter
          return inner_text
        end
      end
    end

  end

end
