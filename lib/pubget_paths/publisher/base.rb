module Publisher
  class Base
    @@journals = {}
    @@ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

    def diff_string(term1, term2, min=20)
      # Absolute diff in length
      String.diff_string(term1, term2, min)
    end

    def parse_html(html, url=nil)
      Nokogiri::HTML(@@ic.iconv(html), url)
    end

    def pubmed_central_path(article)
      path = nil
      unless get_pmcid(article).blank?
        path = "http://www.pubmedcentral.nih.gov/picrender.fcgi?artid=#{get_pmcid(article)}&blobtype=pdf"
        asset_path = path
      end
      path
    end

    def get_doi(article, force=false)
      if article.is_a?(Hash)
        article = article[:article]
      end
      if article.is_a?(Article)
        article.get_doi
      else
        nil
      end
    end
    
    def get_linkouts(article)
      a_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?db=pubmed&tool=pubget&email=iconnor%40pubget.com&id=#{article.pmid}&cmd=llinks"
      content = CachedWebPage.get_cached_url(:url=>a_url)
      urls = []
      content.each_line do |line|
        if url = /<Url>([^<].*)<\/Url>/.match(line)
          urls << url[1]
        end
      end
      urls
    end
    
    def update_source(publisher, grep, issn, eissn, title, title_abbreviation,
                        base_url, frame_busting=false, count=0, uncertain_title=true,
                        pdf_back=nil, pdf_start=nil, pdf_end=nil, secondary_source=true, certain_date=false)
        # The same as jounal but do not change the publisher if it is already there
        update_journal(publisher, grep, issn, eissn, title, title_abbreviation,
                                            base_url, frame_busting, count, uncertain_title,
                                            pdf_back, pdf_start, pdf_end, secondary_source, certain_date)
    end

    def update_journal(publisher, grep, issn, eissn, title, title_abbreviation,
                        base_url, frame_busting=false, count=0, uncertain_title=true,
                        pdf_back=nil, pdf_start=nil, pdf_end=nil, secondary_source=false, certain_date=false)
       # somewhere that can be tested later
       @@journals[publisher] = {} unless @@journals[publisher]
       @@journals[publisher][issn] = {:title=>title, :title_abbreviation=>title_abbreviation, :base_url=>base_url, :eissn=>eissn, :issn=>issn} if issn.present?
       @@journals[publisher][eissn] = {:title=>title, :title_abbreviation=>title_abbreviation, :base_url=>base_url, :eissn=>eissn, :issn=>issn} if eissn.present?
    end
    
    def self.jounal_sources
      @@journals
    end
    

    def raze(text)
      return nil unless text.present?
      text.strip.downcase.gsub(/(?:^\[*)|(?:\]*$)/, '').gsub(/\.$/, '')
    end

    def normalize_str(str)
      begin
        str.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s
      rescue
        str.to_s.split(' ').map { |s| s.scan(/[a-zA-Z_-]/).to_s }.join(' ')
      end
    end
  end
end
