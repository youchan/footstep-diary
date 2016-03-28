require 'sinatra/base'
require 'sinatra/asset_pipeline'
require 'redcarpet'
require 'builder'
require 'rss'
require 'rouge'
require 'rouge/plugins/redcarpet'

class HTMLwithHighlight < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
  # def block_code(code, language)
  #   formatter = Rouge::Formatters::HTML.new(css_class: 'highlight', line_numbers: false)
  #   lexer = case language
  #           when 'ruby'
  #             Rouge::Lexers::Ruby.new
  #           when 'javascript'
  #             Rouge::Lexers::Javascript.new
  #           else
  #             Rouge::Lexers::PlainText.new
  #           end
  #   formatter.format(lexer.lex(code))
  # end
end

class App < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)

    set :assets_precompile, %w(application.css)
    set :assets_css_compressor, :sass

    register Sinatra::AssetPipeline
  end

  get "/" do
    @contents = Dir.glob("#{settings.root}/data/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md").sort.reverse.take(20).map do |filename|
      { date: filename[/(\d{4}-\d{2}-\d{2})\.md/, 1], entry: markdown.render(File.read(filename))}
    end
    haml :index
  end

  get '/rss' do
    @entries = Dir.glob("#{settings.root}/data/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md").sort.reverse.take(20).map do |filename|
      title = File.readlines(filename)[0].sub(/\A\#+ +/, '')
      { date: filename[/(\d{4}-\d{2}-\d{2})\.md/, 1], title: title, description: markdown.render(File.read(filename)) }
    end

    builder :rss
  end

  get /\/(\d{4}-\d{2}-\d{2})/ do
    begin
      date = params[:captures].first
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

  def markdown
    @markdown ||= Redcarpet::Markdown.new(HTMLwithHighlight, autolink: true, tables: true, hard_wrap: true, fenced_code_blocks: true)
  end
end

if __FILE__ == $0
  App.run!
end
