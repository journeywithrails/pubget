require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class InfoTest < ActiveSupport::TestCase
  
  test 'bioone' do
    run_info_for_journals(Publisher::Bioone.new, {
      "1508-1109" => {:eissn => "1733-5329", :title => "Acta Chiropterologica", :base_url => "http://www.bioone.org/loi/acta"},
      "0289-0003" => {:title => "Zoological Science", :base_url => "http://www.bioone.org/loi/jzoo"}
      })
  end


  test 'proquest' do
     run_info_for_journals(Publisher::Proquest.new, {
      "1040-4651" => {:issn => "1040-4651", :eissn => "1532-298X", :title => "The Plant Cel", :base_url => "http://www.plantcell.org/"}    
    })
  end
  
  def run_info_for_journals(pub_class, issns)
    #run the info method
    pub_class.info
    
    #test issn is listed now
    issns.each_pair do |issn, journal_data|
      assert Publisher::Base.jounal_sources[pub_class.source_name].present?, "There should be a rule for this source #{pub_class.source_name}"
      if Publisher::Base.jounal_sources[pub_class.source_name].present?
        assert Publisher::Base.jounal_sources[pub_class.source_name][issn].present?,  "There should be a rule for this issn #{issn}"
        if Publisher::Base.jounal_sources[pub_class.source_name][issn].present?
          journal_data.each_pair do |field, value|
            assert_equal Publisher::Base.jounal_sources[pub_class.source_name][issn][field], value,  "#{issn} #{field} should equal #{value}"
          end
        end
      end
    end
  end
end
