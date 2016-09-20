ENV['RACK_ENV'] ||= 'test'

require_relative '../controllers/application_controller'
require_relative '../controllers/merge_controller'
require_relative '../controllers/register_controller'

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/mini_test'
require 'rack/test'
require 'webmock/minitest'

# Turn on SSL for all requests
class Rack::Test::Session
  def default_env
    { 'rack.test' => true,
      'REMOTE_ADDR' => '127.0.0.1',
      'HTTPS' => 'on'
    }.merge(@env).merge(headers_for_env)
  end
end

class Minitest::Test

  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  def setup
    WebMock.enable!
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)

    ApplicationController.settings.stubs(:api_cache).returns(false)
    ApplicationController.settings.stubs(:mount).returns('')
  end

  def login(session_params = {})
    defaults = {
      'user_id' => '123',
      'user_roles' => ['AccountAdmin'],
      'user_email' => 'test@example.com'
    }

    env 'rack.session', defaults.merge(session_params)
  end
end
