# -*- encoding: utf-8 -*-

module AuthenticationHelpers

  def is_logged?
    session[:authenticated]
  end

  #
  # Log l'utilisateur puis redirige vers 'auth/:provider/callback' qui se charge
  #   d'initialiser la session et de rediriger vers l'url passée en paramètre
  #
  def login!( route )
    redirect "/auth/cas?url=#{URI.encode( 'http://localhost:9292' + route )}"
  end

  #
  # Délogue l'utilisateur du serveur CAS et de l'application
  #
  def logout!( url )
    session[:authenticated] = false
    session[:current_user] = nil

    CASLaclasseCom::OPTIONS[:ssl] ? protocol = 'https://' : protocol = 'http://'
    redirect protocol + CASLaclasseCom::OPTIONS[:host] + CASLaclasseCom::OPTIONS[:logout_url] + '?url=' + URI.encode( url )
  end

  #
  # récupération des données envoyée par CAS
  #
  def set_current_user( env )
    session[:current_user] = { user: nil, info: nil }
    if env['rack.session'][:user]
      session[:current_user][:user] ||= env['rack.session'][:user]
      session[:current_user][:info] ||= env['rack.session'][:extra]
      session[:current_user][:info][:ENTStructureNomCourant] ||= session[:current_user][:extra][:ENTPersonStructRattachRNE]
    end
    session[:current_user]
  end

  #
  # Initialisation de la session après l'authentification
  #
  def init_session( env )
    if env['rack.session']
      env['rack.session'][:user] = env['omniauth.auth'].extra.user
      env['rack.session'][:extra] = env['omniauth.auth'].extra
      session[:authenticated] = true
    end
    set_current_user env
  end

end
