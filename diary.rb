require 'sinatra/base'
require 'sinatra/assetpack'
require 'redcarpet'

class App < Sinatra::Base

  set :root, File.dirname(__FILE__)

  register Sinatra::AssetPack

  assets do
    serve '/js', from: 'app/js'
    serve '/css', from: 'app/css'
    serve '/images', from: 'app/images'

    js :app, '/js/app.js', [
      '/js/lib/**/*.js'
    ]

    css :main, '/css/main.css', [
      '/css/lib/**/*.css'
    ]

    js_compression :jsmin
    css_compression :simple
  end

  get "/" do
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, hard_wrap: true)
    @contents = Dir.glob("data/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md").reverse.map do |filename|
      { date: filename[/data\/(\d{4}-\d{2}-\d{2})\.md/, 1], entry: markdown.render(File.read(filename))}
    end
    haml :index
  end

  get "/:date" do
    begin
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true, hard_wrap: true)
      entry = markdown.render(File.read("data/#{params[:date]}.md"))
      @contents = [{ date: params[:date], entry: entry }]
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
