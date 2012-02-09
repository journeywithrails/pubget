class Publisher::AIP < Publisher::Scitation
  
  def info

    tab_file = "http://librarians.scitation.org/librarians/Scitation_Publications.txt"
    count = 0
    @agent = HackedBrowser.new
    page = @agent.get(:url=>tab_file)
    content = page.body
    issns = []
    actions = {:added=>0, :updated=>0, :total=>0}
    content.split("\n").each do |line|
      row = line.split("\t")
      if row.size > 10
        # Publisher,Full Name,ISSN,Online ISSN,Start Year,Start Vol,Start Issue,End Year,End Vol,End Issue,Embargo Period,Full Text,Peer Reviewed,URL,Note,CODEN
        publisher = row[0]
        title = row[1]
        pissn = (row[2] == "N/A") ? nil : row[2]
        eissn = (row[3] == "N/A") ? nil : row[3]
        next unless pissn =~ /\d\d\d\d-\d\d\d[\dXx]/
        next unless eissn =~ /\d\d\d\d-\d\d\d[\dXx]/
        base_url = row[13]
        issns << pissn if pissn
        issns << eissn if eissn
        unless (publisher =~ /publisher/i)
          count += 1
          action = update_source("AIP", nil, pissn, eissn, title, nil, base_url, true, count)
          actions[:total] += 1
          if action == "added"
            actions[:added] += 1
          elsif action == "updated"
            actions[:updated] += 1
          end
        end
      end
    end
    CheckMonitor.checked("lister_info::aip", 1.months, "Updated lister for AIP", actions[:updated], actions[:added], actions[:total])

  end
  
  def pdf_url(params={})
    article = params[:article]
    key = "#{article.journal.base_url.split("?").last.gsub('/htmltoc','')}"
    puts "key: #{key} from #{article.journal.base_url}"
    if key and article.volume and article.start_page
      return  "http://link.aip.org/link/?#{key}/#{article.volume}/#{article.start_page}/pdf"
    end

    params[:use_pigeon] ||= false
    puts "title: " + article.title
    puts "url: " + issue_url(:article=>article)
    source = CachedWebPage.get_cached_url(:url=>issue_url(:article=>article), :grep=>'aip', :user_agent => "Mozilla/5.0")
    view_all_link = source.match(/<a href="([^"]+)">view all<\/a>/i)
    source = CachedWebPage.get_cached_url(:user_agent => "Mozilla/5.0",
                                          :url=>"http://scitation.aip.org" + view_all_link[1],
                                          :grep=>'aip') if view_all_link
    ####!! makes no sense !!####
    doc = article.parse_html(source)
    #puts doc.inspect
    title_filtered = _filter_letters_digits(title)
    lowest = 10
    lowest_adaptive = article.title_filtered.length
    path = nil
    title_downcase = article.title.downcase

    item_data = nil;
    _enum_sections (source) do |s, t|
      t_filtered = _filter_letters_digits(t)
      diff = diff_string(t_filtered, title_filtered, lowest_adaptive)
      if diff < lowest_adaptive
        lowest_adaptive = diff
        item_data = {:title=>t_filtered, :section=>s}
      end
    end

    valid = false
    if item_data != nil
      if lowest_adaptive < lowest
        valid = true
      elsif lowest_adaptive < article.title_filtered.length / 2 # temporary
        valid = true
        #      else
        #        abstract_page = _get_abstract_page(item_data, params[:use_pigeon])
        #        valid = _validate_by_doi(abstract_page)
      end
    end

    if valid
      path = _node_get_pdf_link(item_data[:section])
      if not path and item_data[:section].inner_html =~ /PDF not available/
        puts "PDF not available!"
      end
    end

    # free-to-read articles handling
    unless path
      lowest = 10 # restore lowest value!
      doc.search("td").each do |td|
        td.search("a").each do |name|
          if name.at("strong")
            term1 = name.at("strong").render_to_plain_text.downcase
            diff = diff_string(term1, title_downcase, lowest)
            if diff < lowest
              abstract_url = "http://scitation.aip.org" + name.at("@href")
              abstract_src = CachedWebPage.get_cached_url(:user_agent => "Mozilla/5.0", :url=>abstract_url, :grep=>'aip')
              abstract_html = parse_html(abstract_src)
              ext_url = nil
              abstract_html.search('div[@id="fulltextdisplay"]/p/a').each do |a|
                if a.render_to_plain_text =~ /^http/
                  ext_url = a.at("@href").value
                  break;
                end
              end
              ext_src = CachedWebPage.get_cached_url(:url=>ext_url, :grep=>'aip', :user_agent => "Mozilla/5.0")
              ext_html = parse_html(ext_src)
              link = ext_html.at('div[@class="aps-deliverablesbar"]/a/@href')
              if link
                lowest = diff
                path = "http://prola.aps.org" + link.value
                # host is temporarily set to fixed value
                # it should be determined automatically!
              end
            end
            break;
          end
        end
      end
    end
    path
  end
  
  def issue_url(params= {})
    article = params[:article]
    key = "#{article.journal.base_url.split("?").last.gsub('/htmltoc','')}"
    "http://scitation.aip.org/dbt/dbt.jsp?KEY=#{key}&Volume=#{article.volume}&Issue=#{article.issue.split(' ')[0]}"
  end
  
  private
    # remove all symbols but letters and digits
    # and separate the "words" by single spaces
    def _filter_letters_digits (str)
      str.scan(/[a-zA-Z0-9]+/).join(' ')
    end

    def _node_get_pdf_link (node)
      path = nil
      node.search("a").each do |a|
        path = "http://scitation.aip.org" + a['href'] if a.render_to_plain_text =~ /PDF|Buy Article/i
      end
      path
    end

    def _enum_sections (source)
      doc = parse_html(source)
      doc.search("ul").each do |ul|
        if ul.at("strong")
          title = ul.at("strong").render_to_plain_text.downcase
          yield ul, title
        end
      end

      doc.search("td").each do |td|
        if td.at("strong")
          title = td.at("strong").render_to_plain_text.downcase
          yield td, title
        end
      end

      _extract_nodes(source, /<div class="toc-right">/, /<div(:?\s|>)/, /<\/div>/) do |frag|
        subdoc = parse_html(frag).at('div[@class="toc-right"]')
        if subdoc
          title_html = subdoc.at('p[@class="art-title"]')
          if title_html
            title = title_html.render_to_plain_text.downcase
            yield subdoc, title
          end
        end
      end
    end

    def _get_abstract_page (item_data, use_pigeon)
      title = item_data[:title]
      s = item_data[:section]
      a_title = nil
      mindiff = -1
      s.search("a").each do |a|
        t = a.render_to_plain_text
        diff = Text::Levenshtein.distance(t, title)
        if mindiff < 0 || mindiff > diff
          mindiff = diff
          a_title = a
        end
      end
      link = a_title.at("@href")
      if link
        CachedWebPage.get_cached_url(:url=>"http://scitation.aip.org" + link, :grep=>'aip', :user_agent => "Mozilla/5.0")
      end
    end

    def _validate_by_doi (abstract_page)
      not self.doi.blank? and abstract_page =~ 'http://links.aip.org/doi/' + self.doi
    end

  
end