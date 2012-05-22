require 'lumber'
require 'sinatra/base'
require 'erb'

module Lumber
  class Server < Sinatra::Base

    configure :development do
      begin
        require "sinatra/reloader"
        register Sinatra::Reloader
      rescue LoadError
      end
    end

    set :root, "#{File.dirname(File.expand_path(__FILE__))}/server"

    get "/" do
      redirect url(:levels)
    end
    
    get "/levels" do
      @levels = LevelUtil.get_levels
      @ttl = LevelUtil.ttl
      erb :levels
    end

    post "/levels" do
      ttl = params['ttl']
      logger_levels = Array(params['levels'])
      levels = {}
      logger_levels.each do |data|
        name = data['name']
        level = data['level'].strip
        levels[name] = level
        if ! Log4r::LNAMES.index(level)
          @error = "Invalid log level: #{level}"
        end
      end
      
      if @error
        @levels = levels
        @ttl = ttl
        erb :levels
      else
        LevelUtil.set_levels(levels)
        LevelUtil.ttl = ttl
        redirect url(:levels)
      end
      
    end
    
    # start the server if ruby file executed directly
    run! if app_file == $0
    
  end
end
