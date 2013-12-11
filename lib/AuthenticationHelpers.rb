# -*- encoding: utf-8 -*-

module AuthenticationHelpers

  def is_logged?
    env['rack.session'][:authenticated]
  end

  #
  # Log l'utilisateur puis redirige vers 'auth/:provider/callback' qui se charge
  #   d'initialiser la session et de rediriger vers l'url passée en paramètre
  #
  def login!( route )
    unless route.empty?
      route += "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
      route = URI.escape( "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{route}" )
      redirect "/auth/cas?url=#{URI.encode( route )}"
    end
    redirect '/auth/cas'
  end

  #
  # Délogue l'utilisateur du serveur CAS et de l'application
  #
  def logout!( url )
    env['rack.session'][:authenticated] = false
    env['rack.session'][:current_user] = nil

    CASLaclasseCom::OPTIONS[:ssl] ? protocol = 'https://' : protocol = 'http://'
    redirect protocol + CASLaclasseCom::OPTIONS[:host] + CASLaclasseCom::OPTIONS[:logout_url] + '?url=' + URI.encode( url )
  end

  #
  # récupération des données envoyée par CAS
  #
  def set_current_user( env )
    env['rack.session'][:current_user] = { user: nil, info: nil }
    if env['rack.session'][:user]
      env['rack.session'][:current_user][:user] ||= env['rack.session'][:user]
      env['rack.session'][:current_user][:info] ||= env['rack.session'][:extra]
      env['rack.session'][:current_user][:info][:ENTStructureNomCourant] ||= env['rack.session'][:current_user][:extra][:ENTPersonStructRattachRNE]
    end
    env['rack.session'][:current_user]
  end

  #
  # Initialisation de la session après l'authentification
  #
  def init_session( env )
    if env['rack.session']
      env['rack.session'][:user] = env['omniauth.auth'].extra.user
      env['rack.session'][:extra] = env['omniauth.auth'].extra
      env['rack.session'][:authenticated] = true
    end
    set_current_user env
  end

end
