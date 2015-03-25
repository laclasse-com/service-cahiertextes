# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Auth
      def self.registered( app )
        app.get "#{APP_PATH}/auth/:provider/callback" do
          init_session( request.env )

          provision( user )

          redirect_uri = URI( params[:url] )
          redirect "#{redirect_uri.path}?#{redirect_uri.query}##{redirect_uri.fragment}"
        end

        app.get "#{APP_PATH}/logout" do
          logout! "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{APP_PATH}/"
        end

        # Personne ne devrait jamais arriver sur les 2 routes suivantes...
        app.get "#{APP_PATH}/auth/failure" do
          erb :auth_failure
        end

        app.get "#{APP_PATH}/auth/:provider/deauthorized" do
          erb :auth_deauthorized
        end

        # Login pour les applications tierces, en mode WEB
        app.get "#{APP_PATH}/login/?" do
          login! "#{APP_PATH}/"
        end

        app.get "#{APP_PATH}/quiet_login/?" do
          login! "#{APP_PATH}/rien/"
        end

        # POST pour le login en mode REST, pour les applications souhaitant utiliser les API du Cahier de Textes.
        # Dans ce cas le paramètre restmod et requis.
        # Exemple avec curl :
        # curl --data "username=$USER&password=$PWD" --cookie-jar ./cookieCT.txt --insecure --location http://[Server]/ct/login/?restmod=Y
        # Voir le  script d'exemple dans les specs.
        # @see ./spec/api/test_login_curl_proxy.sh
        app.post "#{APP_PATH}/login/?" do
          login! "#{APP_PATH}/"
        end
      end
    end
  end
end
