require 'resque/tasks'
require 'resque/scheduler/tasks'

task :'resque:setup' do
  Dir.glob(File.join('./workers', '*.rb'), &method(:require))
end
