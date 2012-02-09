require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase

  def setup
    Article.load_articles
  end

  test "the finder" do
    a = Article.find_by_pmid('19216642')
    assert_equal "19216642", a.pmid, "article pmid should equal 19216642 but was #{a.pmid}"
  end

  test "the getter" do
    a = Article.find_by_pmid('19216642')
    expected_title = "Buffered platelet-rich plasma enhances mesenchymal stem cell proliferation and chondrogenic differentiation."
    assert_equal expected_title, a.title
  end

  test "the setter" do
    a = Article.find_by_pmid('19216642')
    expected_title = "Buffered platelet-rich plasma enhances mesenchymal stem cell proliferation and chondrogenic differentiation."
    assert_equal expected_title, a.title
    a.title= "new_title"
    assert_not_equal expected_title, a.title
  end
end
