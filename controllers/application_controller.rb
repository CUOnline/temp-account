require 'bundler/setup'
require 'wolf_core'
require 'sinatra/formkeeper'
require 'resque-scheduler'

Dir.glob(File.join('helpers', '*.rb'), &method(:require))
Dir.glob(File.join('lib', '*.rb'), &method(:require))

class ApplicationController < WolfCore::App
  set :root, File.expand_path(File.join(File.dirname(__FILE__), '..'))
  set :logger, create_logger
  set :api_cache, false

  register Sinatra::FormKeeper
  register Sinatra::Flash
  register Sinatra::CanvasAuth
  set :auth_paths, [/\/register\z/]

  # Set as helpers for use in controllers,
  # Register as class methods for use in workers
  register ApplicationHelper
  helpers ApplicationHelper

  get '/' do
    redirect "#{mount_point}/register"
  end
end
