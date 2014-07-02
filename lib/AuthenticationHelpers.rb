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
      route = CGI.escape( "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{route}" )

      #      redirect "#{APP_PATH}/auth/cas?url=#{URI.encode( route )}"
puts "Dans login!, route="+route.inspect
puts "on redirige vers route="+"#{APP_PATH}/auth/cas?url=#{route}"
    #  redirect "#{APP_PATH}/auth/cas?url=#{URI.encode( route )}"
      redirect "#{APP_PATH}/auth/cas?url=#{route}"
    end
    redirect "#{APP_PATH}/auth/cas"
  end

  #
  # Délogue l'utilisateur du serveur CAS et de l'application
  #
  def logout!( url )
    env['rack.session'][:authenticated] = false
    env['rack.session'][:current_user] = nil

    CASAuth::OPTIONS[:ssl] ? protocol = 'https://' : protocol = 'http://'
    redirect protocol + CASAuth::OPTIONS[:host] + CASAuth::OPTIONS[:logout_url] + '?url=' + URI.encode( url )
  end

  def provisionning( uais )
    # 0. Établissements
    uais.each {
      |uai|
      if Etablissement.where(UAI: uai).first.nil?
        etablissement = Annuaire.get_etablissement( uai )
        Etablissement.create(UAI: etablissement['code_uai'])
        etablissement['classes'].each {
          |classe|
          CahierDeTextes.create( regroupement_id: classe['id']  )
        }
      end
    }
  end

  #
  # Initialisation de la session après l'authentification
  #
  def init_session( env )
    STDERR.puts '. . initialisation de la session'
    unless env['rack.session'].nil? || env['omniauth.auth'].nil?
      env['rack.session'][:authenticated] = true

      user_annuaire = Annuaire.get_user( env['omniauth.auth'].extra.uid )
      env['rack.session'][:current_user] = { 'user' => env['omniauth.auth'].extra.user,
                                             'uid' => env['omniauth.auth'].extra.uid,
                                             'LaclasseNom' => user_annuaire['nom'],
                                             'LaclassePrenom' => user_annuaire['prenom'],
                                             'ENTPersonProfils' => user_annuaire['profils'].map { |p| "#{p['profil_id']}:#{p['etablissement_code_uai']}" }.join( ',' ) }

      uais = user_annuaire['profils'].map {
        |profil|
        profil['etablissement_code_uai']
      }.uniq

      provisionning( uais )
    end

    env['rack.session'][:current_user]
  end
end
