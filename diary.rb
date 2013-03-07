# coding: utf-8

require 'rubygems'
require 'sinatra'
require 'redcarpet'

get "/" do
  @content = "ここに記事がはいります。"
  erb :index
end
