require File.dirname(__FILE__) + '/diary.rb'

Process.daemon
App.run! :host => 'localhost', :port => 3002
