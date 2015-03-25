# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Index
      def self.registered( app )
        app.get "#{APP_PATH}/?" do
          erb :app
        end

        app.get "#{APP_PATH}/rien/?" do
          erb :rien
        end
      end
    end
  end
end
