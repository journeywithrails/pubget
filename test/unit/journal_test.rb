require File.dirname(__FILE__) + '/../test_helper'

class JournalTest < ActiveSupport::TestCase
  
  def setup
    Journal.load_journals
  end
  
  test "the finder" do
    j = Journal.find_by_issn('1471-0056')
    assert_equal "1471-0056", j.issn, "journal issn should equal 1471-0056 but was #{j.issn}"
  end
  
  test "the getter" do
    j = Journal.find_by_issn('1471-0056')
    expected_title = "Nature Reviews Genetics"
    assert_equal expected_title, j.title
  end
  
  test "the setter" do
    j = Journal.find_by_issn('1471-0056')
    expected_title = "Nature Reviews Genetics"
    assert_equal expected_title, j.title
    j.title= "new_title"
    assert_not_equal expected_title, j.title
  end
end
