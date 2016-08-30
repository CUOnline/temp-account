ENV['RACK_ENV'] ||= 'test'

require_relative '../controllers/application_controller'
require_relative '../controllers/merge_controller'
require_relative '../controllers/register_controller'

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/mini_test'
require 'rack/test'
require 'byebug'

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
    # Duplicates config.ru routing
    Rack::Builder.new do
      map '/' do
        run ApplicationController
      end
      map '/register' do
        run RegisterController
      end
      map '/merge' do
        run MergeController
      end
    end
  end

  def setup
    ApplicationController.set :mount, ''
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
