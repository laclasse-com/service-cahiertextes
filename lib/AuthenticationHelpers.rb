# -*- encoding: utf-8 -*-
require 'rest-client'
require 'nokogiri'

module AuthenticationHelpers

  def get_protocol
    CASAUTH::CONFIG[:ssl] ? 'https://' : 'http://'
  end

  def is_logged?
    env['rack.session'][:authenticated]
  end

  #
  # Logue l'utilisateur puis redirige vers 'auth/:provider/callback' qui se charge
  #   d'initialiser la session et de rediriger vers l'url passée en paramètre
  #
  # En mode REST, pas de redirection vers cas/auth, création d'une session avec init_session
  def login!( route, quiet = false )
    unless route.empty?
      route += "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
      route = CGI.escape( "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{route}" )
    end
    if !params[:restmod].nil?
      # Mode Rest
      cas_token = cas_dialog_proxiing route

      # Gestion d'erreur
      unless cas_token[:error].empty?
        STDERR.puts 'REST authentication failure !'
        STDERR.puts cas_token[:error].to_s
        halt 401, { error: cas_token[:error] }.to_json
      end
      init_session( env, cas_token[:user], cas_token[:uid] )
      # Ici tout est ok,on renvoie 200 ok car tout s'est admiraaaaablement bien passé....
      status 200

    else
      if quiet
        status 200
      else
        # Mode normal : navigateur classique
        redirect "#{APP_PATH}/auth/cas" if route.empty?

        redirect "#{APP_PATH}/auth/cas?url=#{route}"
      end
    end
  end

  #
  #  Dialogue avec CAS et
  #  Analyse et lecture du jeton CAS,
  #  pour le mode login REST.
  #
  def cas_dialog_proxiing(route)
    cas = {}
    cas[:error] = ''
    # 1. Poster l'authentification CAS et récupérer un TGT
    tgt = RestClient.post get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:restmod_url],
                          username: params[:username],
                          password: params[:password]
    # 2. Récupérer un ST
    st = RestClient.post get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:restmod_url] + '/' + tgt.to_s,
                         service: "#{route}"
    # 3. valider le Service Ticket et recevoir le jeton xml
    token = RestClient.get get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:service_validate_url],
                           params: { service: "#{route}", ticket: st.to_s }
    # 4. Analyse de la réponse de CAS.
    doc  = Nokogiri::XML( token ).remove_namespaces!
    cas_response = doc.xpath '//serviceResponse/authenticationSuccess'
    # gestion d'erreur CAS
    if cas_response.empty?
      # authenticationSuccess n'existe pas, il y a donc une erreur d'authetification
      cas[:error] = cas_response = doc.xpath('//serviceResponse/authenticationFailure/text()').to_s
    end
    cas[:user] = doc.xpath('////user/text()').to_s
    cas[:uid]  = doc.xpath('////uid/text()').to_s
    cas
  end

  #
  # Délogue l'utilisateur du serveur CAS et de l'application
  #
  def logout!( url )
    env['rack.session'][:authenticated] = false
    env['rack.session'][:current_user] = nil

    redirect get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:logout_url] + '?url=' + URI.encode( url )
  end

  def provisionning( uais )
    # 0. Établissements
    uais.each {
      |uai|
      if Etablissement.where(UAI: uai).first.nil?
        etablissement = Annuaire.get_etablissement( uai )
        Etablissement.create(UAI: etablissement['code_uai'])
        etablissement['classes']
          .concat( etablissement['groupes_eleves'] )
          .concat( etablissement['groupes_libres'] )
          .each {
          |regroupement|
          cdt = CahierDeTextes.where( regroupement_id: regroupement['id'] ).first
          CahierDeTextes.create( regroupement_id: regroupement['id'] ) if cdt.nil?
        }
      end
    }
  end

  #
  # Initialisation de la session après l'authentification
  #
  def init_session( env, user_rest = '', uid_rest = '' )
    # Voir si on est passé par Omniauth ou pas
    # Dans le cas d'une connexion en mode REST, on ne passe pas par omniAuth
    if env['omniauth.auth'].nil?
      username = user_rest
      uid = uid_rest
    else
      username = env['omniauth.auth'].extra.user
      uid = env['omniauth.auth'].extra.uid
    end

    user_annuaire = Annuaire.get_user( uid )

    unless env['rack.session'].nil? || user_annuaire.nil?
      env['rack.session'][:authenticated] = true

      env['rack.session'][:current_user] = { 'user' => username,
                                             'uid' => uid,
                                             'LaclasseNom' => user_annuaire['nom'],
                                             'LaclassePrenom' => user_annuaire['prenom'],
                                             'ENTPersonProfils' => user_annuaire['profils'].map { |p| "#{p['profil_id']}:#{p['etablissement_code_uai']}" }.join( ',' ) }

      uais = user_annuaire['profils'].map {
        |profil|
        profil['etablissement_code_uai']
      }.uniq

      provisionning( uais )
    end

    env['rack.session'][:current_user].each do |key, _value|
      env['rack.session'][:current_user][ key ] = URI.unescape( env['rack.session'][:current_user][ key ] ) if env['rack.session'][:current_user][ key ].is_a? String
    end

    env['rack.session'][:current_user]
  end
end
