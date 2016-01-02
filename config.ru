require File.dirname(__FILE__) + '/diary.rb'

if ENV['RACK_ENV'] == 'production'
  Process.daemon
end
App.run! :host => 'localhost', :port => 3002
