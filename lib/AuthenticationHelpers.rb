# -*- encoding: utf-8 -*-
require 'rest-client'

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
  def login!( route )
    unless route.empty?
      route += "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
      route = CGI.escape( "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{route}" )
    end
    if !params[:restmod].nil?
      puts; 120.times { putc '-' }; puts '-'
      puts params.inspect 
      # Mode Rest
      # 1. Poster l'authentification CAS et récupérer un TGT
      tgt = RestClient.post get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:restmod_url], 
                      :username => params[:username],
                      :password => params[:password]
      puts; 120.times { putc '-' }; puts '-'
      puts "received tgt from CAS : #{tgt}"
      #2. Récupérer un ST
      st = RestClient.post get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:restmod_url] + '/' + tgt.to_s,
                           :service => "#{route}"
      puts; 120.times { putc '-' }; puts '-'
      puts "received st from CAS : #{st}"
      # 3. valider le Service Ticket et recevoir le jeton xml
      token = RestClient.get get_protocol + CASAUTH::CONFIG[:host] + CASAUTH::CONFIG[:service_validate_url], 
                             {:params => {:service => "#{route}", :ticket => st.to_s}}
                           
      puts; 120.times { putc '-' }; puts '-'
      puts "reading xml token from CAS : #{token}"
      #
      # TODO : Gestion d'erreur
      # TODO : Parser le token xml pour trouver User et Uid
      # TODO : Faire le boulot d'OmniAuth : session rack, notamment.
      #
      init_session( env, "BAS14ELV11", "VAX64436" )
      puts; 120.times { putc '-' }; puts '-'
      puts env.inspect      
      puts; 120.times { putc '-' }; puts '-'; puts
    else
      # Mode narmol : navigateur classique
      if route.empty?
        redirect "#{APP_PATH}/auth/cas"
      end
      redirect "#{APP_PATH}/auth/cas?url=#{route}"
    end
    
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
  def init_session( env, user_rest="", uid_rest="" )
    STDERR.puts '. . initialisation de la session'
    # Voir si on est passé par Omniauth ou pas 
    # Dans le cas d'une connexion en mode REST, on ne passe pas par omniAuth
    unless env['omniauth.auth'].nil?
      username = env['omniauth.auth'].extra.user
      uid = env['omniauth.auth'].extra.user
    else
      username = user_rest
      uid = uid_rest
    end
    
    unless env['rack.session'].nil? 
      env['rack.session'][:authenticated] = true
      
      user_annuaire = Annuaire.get_user( uid )
      env['rack.session'][:current_user] = { 'user' => username,
        'uid' => uid ,
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
