require 'resque/tasks'
require 'resque/scheduler/tasks'
require 'rake/testtask'

task :'resque:setup' do
  Dir.glob(File.join('./workers', '*.rb'), &method(:require))
end

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
  t.verbose = false
end
