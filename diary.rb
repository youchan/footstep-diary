require 'sinatra/base'
require 'sinatra/asset_pipeline'
require 'redcarpet'
require 'builder'
require 'rss'

class App < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)

    set :assets_precompile, %w(application.css)
    set :assets_css_compressor, :sass

    register Sinatra::AssetPipeline
  end

  get "/" do
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, hard_wrap: true)
    @contents = Dir.glob("#{settings.root}/data/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md").sort.reverse.take(20).map do |filename|
      { date: filename[/(\d{4}-\d{2}-\d{2})\.md/, 1], entry: markdown.render(File.read(filename))}
    end
    haml :index
  end

  get '/rss' do
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, hard_wrap: true)
    @entries = Dir.glob("#{settings.root}/data/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md").sort.reverse.take(20).map do |filename|
      title = File.readlines(filename)[0].sub(/\A\#+ +/, '')
      { date: filename[/(\d{4}-\d{2}-\d{2})\.md/, 1], title: title, description: markdown.render(File.read(filename)) }
    end

    builder :rss
  end

  get /\/(\d{4}-\d{2}-\d{2})/ do
    begin
      date = params[:captures].first
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, hard_wrap: true)
      md_content = File.read("#{settings.root}/data/#{date}.md")
      entry = markdown.render(md_content)
      @title = md_content.split("\n").first.sub(/^#(.+\Z)/, '\1').strip if md_content =~ /^# /
      @contents = [{ date: date, entry: entry }]
    rescue
      @contents = []
      @error = "お探しのページは見つかりませんでした…"
      status 404
    end
    haml :index
  end
end

if __FILE__ == $0
  App.run!
end
