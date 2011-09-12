require "test/unit"

require_relative "../lib/hateda"
require "pp"

class TestBookmarks < Test::Unit::TestCase
  def setup
    @total = 1612
    @bm = Hatena::Bookmarks.new(:keyesberry)
  end

  def test_dataset
    # @bm.clear
    p @bm.dataset
  end

  def test_total
    url = "http://d.hatena.ne.jp/keyesberry"
    bms = @bm.total
    assert_equal(@total, bms)
  end
end
