require "test/unit"

require_relative "../lib/bookmarks"
require "pp"

class TestBookmarks < Test::Unit::TestCase
  def setup
    @total = 1612
    @bm = Hatena::Bookmarks.new(:keyesberry)
  end

  def test_dataset_with_file
    path = Dir.pwd + '/test'
    @bm.get_dataset([path+'/keyesberry0.html', path+'/keyesberry1539.html'])
    p @bm.stat_by(:marker) { |k, i| i > 0 }
    p @bm.stat_by(:tags) { |k, i| k.include? 'ruby' }
  end

  def test_dataset
    @bm.clear
    @bm.dataset
    p @bm.stat_by(:marker) { |k, i| i > 3 }
    p @bm.stat_by(:title) { |k, i| i > 10 }
  end

  def test_total
    url = "http://d.hatena.ne.jp/keyesberry"
    bms = @bm.total
    assert_equal(@total, bms)
  end
end