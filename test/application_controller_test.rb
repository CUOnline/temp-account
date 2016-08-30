require_relative './test_helper'

class ApplicationControllerTest < Minitest::Test
  def test_get
    login
    get '/'

    assert_equal 302, last_response.status
    assert_equal 'https://example.org/register', last_response.headers["Location"]
  end
end
