require './controllers/application_controller'
Dir.glob(File.join('./controllers', '*.rb'), &method(:require))

map('/')         { run ApplicationController }
map('/register') { run RegisterController    }
map('/merge')    { run MergeController       }
