# coding: utf-8

# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/environment'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './config/CASLaclasseCom'
require_relative './lib/AuthenticationHelpers'

# Application Sinatra servant de base
module CahierDeTextesAPI
  class AuthApp < Sinatra::Base

    configure do
      set :protection, true
      set :inline_templates, true
    end

    helpers AuthenticationHelpers

    get '/' do
      erb "<a href='/cahier_de_textes'>Vers l'application Cahier de Textes</a>"
    end

    get '/auth/:provider/callback' do
      init_session( request.env )

      if params[:url] != '/'
        redirect params[:url]
      else
        erb "<a href='/app/index.html'>You're drunk, go home!</a>
         <h1>#{params[:provider]}</h1>
         <pre>#{JSON.pretty_generate(request.env['omniauth.auth'])}</pre>
         <pre>#{request.env.pretty_inspect}</pre>
         <pre>#{session[:current_user].pretty_inspect}</pre>"
      end
    end

    get '/auth/failure' do
      erb "<h1>Authentication Failed:</h1><h3>message:<h3> <pre>#{params}</pre>"
    end

    get '/auth/:provider/deauthorized' do
      erb "#{params[:provider]} has deauthorized this app."
    end

    get '/logout' do
      logout! 'http://localhost:9292/'
    end

  end
end

AuthApp.run! if __FILE__ == $PROGRAM_NAME

__END__

@@ layout
<html>
<head>
<link href='//netdna.bootstrapcdn.com/bootstrap/3.0.2/css/bootstrap.min.css' rel='stylesheet' />
</head>
<body>
<div class="navbar col-md-12">
<div class="navbar-header">
<a class="navbar-brand" href="/">POC GAR</a>
</div>
<ul class="navbar-nav nav pull-right">
<% unless is_logged? %>
<li>
<a href='/auth/cas'>Login with Laclasse.com</a><br>
</li>
<% else %>
<li>
<a href='/logout'>Log out</a>
</li>
<% end %>
</ul>
</div>
<h1>Démonstrateur connexion laclasse.com <-> GAR</h1>
<div class='container'>
<div class='content'>
<%= yield %>
</div>
</div>
</body>
</html>
