require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::EBSCO::EDS::VERSION
  end

end
