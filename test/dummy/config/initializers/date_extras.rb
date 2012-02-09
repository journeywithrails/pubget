
class Date

  # Will interpret a string like "December 2008" as 2008-12-01.
  def self.parse_allow_no_day(date_str)
    if date_str.match(/^[A-Z][a-z]+,? [0-9]{4,}$/)
      date_str = "1 " + date_str
    end
    return Date.parse(date_str)
  end

  def self.date_from_string(date_str, format='us', take_lowest=true, century='19')
    debug = false
    date_str = date_str.gsub(/Early|Late\s?/i,"")

    if format.downcase != 'us'
      date_str = self.send("date_from_string_#{format.downcase}",date_str)
    end
    if matches = date_str.match(/(Win|Winter).*([0-9]{4,})$/i)
      puts "date_match: #{__LINE__}" if debug
      if date_str =~ /Autumn|Fall/i
        if take_lowest
          date_str = "22 September " + matches[2]
        else
          date_str = "22 December " + matches[2]
        end
      else
        date_str = "22 December " + matches[2]
      end
    elsif matches = date_str.match(/(Spring).*([0-9]{4,})$/i)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "22 March " + matches[2]
      else
        date_str = "22 June " + matches[2]
      end
    elsif matches = date_str.match(/(Summer).*([0-9]{4,})$/i)
      puts "date_match: #{__LINE__}" if debug
      date_str = "22 June " + matches[2]
    elsif matches = date_str.match(/(Autumn|Fall).*([0-9]{4,})$/i)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "22 September " + matches[2]
      else
        date_str = "22 December " + matches[2]
      end
    elsif matches = date_str.match(/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\.?[\s]{0,1}[-|\/][\s]{0,1}(Jan)\.?,?\s?([0-9]{4,})[-|\/]?([0-9]{4,})?/i)
      puts "date_match: #{__LINE__}" if debug
      date_str = "1 " + matches[1] + " " + matches[3]
    elsif date_str.match(/^[A-Z][a-z]+,? [0-9]{4,}$/)
      puts "date_match: #{__LINE__}" if debug
      date_str = "1 " + date_str
    elsif matches = date_str.match(/^([A-Z][a-z]+)[\s]{0,1}-[\s]{0,1}([A-Z][a-z]+) ([0-9]{4,})$/)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 #{matches[1]} #{matches[3]}"
      else
        date_str = "1 #{matches[2]} #{matches[3]}"
      end
    elsif matches = date_str.match(/^([A-Z][a-z]+) ([0-9]{4,})[\s]{0,1}-[\s]{0,1}([A-Z][a-z]+) ([0-9]{4,})$/)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 #{matches[1]} #{matches[2]}"
      else
        date_str = "1 #{matches[3]} #{matches[4]}"
      end
    elsif years = date_str.match(/^([0-9]{4,})[\s]{0,1}(?:-|\/)[\s]{0,1}([0-9]{4,})$/)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 January " + "#{years[1]}"
      else
        date_str = "31 December " + "#{years[2]}"
      end
    elsif years = date_str.match(/^([0-9]{4,})\/\/\s?$/)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 January " + "#{years[1]}"
      else
        date_str = "31 December " + "#{years[2]}"
      end
    elsif matches = date_str.match(/^([0-9]{1,})[\S]{2,2}[\s]{0,1}Quarter[\s]{0,1}([0-9]{4,})$/)
      puts "date_match: #{__LINE__}" if debug
      quarters = ["January", "January","April","July","October"]
      date_str = "1 #{quarters[matches[1].to_i]} #{matches[2]}"
    elsif matches = date_str.match(/\(([0-9]{1,})[\S]{2,2}[\s]{0,1}Quarter[\s]{0,1}([0-9]{4,})\)/)
      puts "date_match: #{__LINE__}" if debug
      quarters = ["January", "January","April","July","October"]
      date_str = "1 #{quarters[matches[1].to_i]} #{matches[2]}"
    elsif matches = date_str.match(/^([0-9]{2,})-([0-9]{2,})-([0-9]{4,})$/)
      puts "date_match: #{__LINE__}" if debug
      date_str = "#{matches[1]}/#{matches[2]}/#{matches[3]}"
    elsif date_str.match(/^[0-9]{4,4}$/)
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 January " + date_str
      else
        date_str = "31 December " + date_str
      end
    elsif days = date_str.match(/^(.+) days? ago/i)
      puts "date_match: #{__LINE__}" if debug
      today = Date.today
      day = today.day
      month = today.month
      year = today.year
      base_date = Date.new(year, month, day)
      back = base_date - (days[1].to_i)
      # round down to the first of the month
      date_str = Date.new(back.year, back.month, 1).to_s()
    elsif months = date_str.match(/^(.+) months? ago/i)
      puts "date_match: #{__LINE__}" if debug
      today = Date.today
      day = today.day
      month = today.month
      year = today.year
      base_date = Date.new(year, month, day)
      back = base_date - 28*(months[1].to_i)
      # round down to the first of the month
      date_str = Date.new(back.year, back.month, 1).to_s()
    elsif years = date_str.match(/^(.+) years? ago/i)
      puts "date_match: #{__LINE__}" if debug
      date_str = self.years_ago(years[1].to_i)
    elsif date_str =~ /last calendar year/i
      puts "date_match: #{__LINE__}" if debug
      date_str = self.years_ago(1)
    elsif date_str =~ /current calendar year/i
      puts "date_match: #{__LINE__}" if debug
      year = Date.today.year
      if take_lowest
        date_str = "1 January #{year}"
      else
        date_str = "31 December #{year}"
      end
    elsif years = date_str.match(/previous (\d+) years/i)
      puts "date_match: #{__LINE__}" if debug
      date_str = years[1]
    elsif date_str =~ /current year/i
      puts "date_match: #{__LINE__}" if debug
      date_str = "#{Date.today.year}-12-31"
    elsif date_str =~ /current week/i
      puts "date_match: #{__LINE__}" if debug
      today = Date.today
      current_week = Date.new(today.year, today.month, -1)
      date_str = current_week.to_s
    elsif date_str =~/^current$/i
      puts "date_match: #{__LINE__}" if debug
      date_str = Date.today.to_s
    elsif date_str =~ /^\d{2,2}$/
      puts "date_match: #{__LINE__}" if debug
      if take_lowest
        date_str = "1 January #{century}#{date_str}"
      else
        date_str = "31 December #{century}#{date_str}"
      end
    elsif date_str =~ /present/i
      puts "date_match: #{__LINE__}" if debug
      date_str = "31 December #{Time.now.year}"
    elsif matches = date_str.match(/^(\d{4,4})(\d{2,2})(\d{2,2})$/)
      year = matches[1]
      month = matches[2]
      month = '01' if month == '00'
      day = matches[3]
      day = '01' if day == '00'
      date_str = "#{month}/#{day}/#{year}"
    elsif matches = date_str.match(/^(\d{4,4})\/(\d{2,2})$/)
      puts "date_match: #{__LINE__}" if debug
      start_year = matches[1]
      end_year = matches[2]
      date_str = "1 January #{start_year[0..1]}#{end_year}"
    elsif date_str =~ /(current|most recent) issues?/i
      puts "date_match: #{__LINE__}" if debug
      date_str = Date.today.to_s
    elsif date_str =~ /^select articles$/i
      puts "date_match: #{__LINE__}" if debug
      # not much we can do in this case
      return nil
    elsif date_str =~ /recent issues/
      puts "date_match: #{__LINE__}" if debug
      # again not much we can do
      return nil
    elsif matches = date_str.match(/(\d{1,2}\s[a-z]+\s\d{4,4})\-(\d{1,2}\s[a-z]+\s\d{4,4})/i)
      puts "date_match: #{__LINE__}" if debug
      #28 November 2009-4 December 2009
      if take_lowest
        date_str = matches[1]
      else
        date_str = matches[2]
      end
    elsif matches = date_str.match(/(?: |\()(\d{4,4})(?: |\)|\-)/)
      puts "date_match: #{__LINE__}" if debug
      # sort of the default case
      # if we can match 4 numbers, call it a year and move on
      year = matches[1]
      date_str = "1 January #{year}"
    elsif matches = date_str.match(/YEAR: (\d{4,4})('s)?/)
      puts "date_match: #{__LINE__}" if debug
      year = matches[1]
      date_str = "1 January #{year}"
    elsif matches = date_str.match(/(\d{4,4})('s)/)
      puts "date_match: #{__LINE__}" if debug
      year = matches[1]
      date_str = "1 January #{year}"
    elsif matches = date_str.match(/(\d{4,4})\/\d{4,4} - \d{4,4}\/\d{4,4}/)
      puts "date_match: #{__LINE__}" if debug
      year = matches[1]
      date_str = "1 January #{year}"
    elsif matches = date_str.match(/(\d{4,4})-(\d{1,2})/)
      puts "date_match: #{__LINE__}" if debug
      year = matches[1]
      month = matches[2]
      if take_lowest
        date_str = "#{month}/01/#{year}"
      else
        date_str = "#{month}/31/#{year}"
      end
    elsif matches = date_str.match(/(?: *|\()(\d{4,4})(?: |\)|\-)/)
      puts "date_match: #{__LINE__}" if debug
      # sort of the default case
      # if we can match 4 numbers, call it a year and move on
      year = matches[1]
      date_str = "1 January #{year}"
    elsif date_str =~ /^\w{3,3}\-\d{2,2}$/
      date_str = "1-#{date_str}"
    end
    # Spell check date
    if matches = date_str.match(/(\d{1,2})\s([A-Za-z]+)\s(\d{4,4})/)
      puts "date_match: #{__LINE__}" if debug
      day_part = matches[1]
      year_part = matches[3]
      month_part = matches[2]
      if Date::ABBR_MONTHNAMES.include?(month_part.capitalize)
        # No mistakes
      elsif Date::MONTHNAMES.include?(month_part.capitalize)
        # No mistakes
      else
        # test full month names
        fixed = false
        Date::MONTHNAMES.each do |month_name|
          if month_name
            lowest = 3
            diff = Text::DamerauLevenshtein.distance(month_name, month_part)
            if (diff < lowest)
              lowest = diff
              month_part = month_name
              fixed = true
            end
          end
        end
        # also test abbreviations, but only use levenshtein of 1
        unless fixed
          Date::ABBR_MONTHNAMES.each do |month_name|
            if month_name
              lowest = 2
              diff = Text::DamerauLevenshtein.distance(month_name.downcase, month_part.downcase)
              if (diff < lowest)
                lowest = diff
                month_part = month_name
              end
            end
          end
        end
        puts "date_match: #{__LINE__}" if debug
        date_str = "#{day_part} #{month_part} #{year_part}"
      end
    end

    begin
      ret_date = Date.parse(date_str)
      ret_date = fixup_y2k_date(ret_date)
      ret_date
    rescue
      puts $! if debug
      nil
    end
  end

  def self.fixup_y2k_date(ret_date)
    if ret_date.year < 30
      ret_date = Date.civil(ret_date.year + 2000, ret_date.month, ret_date.day)
    elsif ret_date.year < 100
      ret_date = Date.civil(ret_date.year + 1900, ret_date.month, ret_date.day)
    elsif ret_date.year < 1000
      ret_date = Date.civil(ret_date.year + 1000, ret_date.month, ret_date.day)
    end
    ret_date
  end

  def self.date_from_string_au(date_string)
    if date_string =~ /([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4,})/
      date_parts = date_string.split('/')
      return "#{date_parts[1]}/#{date_parts[0]}/#{date_parts[2]}"
    else
      return date_string
    end
  end

  def self.date_from_string_uk(date_string)
    return self.date_from_string_au(date_string)
  end

  def self.date?(date_string)
    if date_string =~ /\d{4,}|\d{1,2}\/\d{1,2}\/\d{2,4}/
      return true
    else
      return false
    end
  end

  def self.years_ago(years)
    today = Date.today
    day = today.day
    month = today.month
    year = today.year
    base_date = Date.new(year, month, day)
    back = base_date - 365*(years[1].to_i)
    # round down to the first of the month
    return Date.new(back.year, back.month, 1).to_s()
  end

  def self.months_ago(months, date = nil)
    today = date ? date : Date.today
    return today << months


  end

  def self.first_day_of_the_month(yyyy, mm)
    new(yyyy, mm, 1)
  end

  def self.last_day_of_the_month(yyyy, mm)
    d = new(yyyy, mm)
    d += 42                  # warp into the next month
    new(d.year, d.month) - 1 # back off one day from first of that month
  end

  def self.solr_date_string( delta_from_today )
    d = Date.today - delta_from_today
    "#{d.year}-#{d.month}-#{d.day}"
  end

  def weekend?
    if Date::DAYNAMES[self.wday] =~ /Sunday|Saturday/
      true
    else
      false
    end
  end

  def quarter
    if month.between?(1,3)
      return 1
    elsif month.between?(4,6)
      return 2
    elsif month.between?(7,9)
      return 3
    elsif month.between?(10,12)
      return 4
    end
  end
end
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end

  def weekend?
    self.to_date.weekend?
  end
end
