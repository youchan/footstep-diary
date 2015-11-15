require 'sinatra/base'
require 'sinatra/assetpack'

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
      '/css/main.css'
    ]

    js_compression :jsmin
    css_compression :simple
  end

  get "/" do
    erb :index
  end

end

if __FILE__ == $0
  App.run!
end
