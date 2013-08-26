# coding: utf-8

require 'sinatra/base'
require 'sinatra/reloader'
require 'redcarpet'

class Diary < Sinatra::Base
  set :sessions, true

  get "/" do
    redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    @content = redcarpet.render(File.read(File.dirname(__FILE__) + "/data/2013-08-26.md"))
    erb :index
  end
end
