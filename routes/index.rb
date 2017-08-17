# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Index
      def self.registered( app )
        app.get '/?' do
          erb :app
        end

        app.get '/rien/?' do
          erb :rien
        end
      end
    end
  end
end
