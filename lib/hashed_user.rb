# encoding: utf-8

require_relative './hash_it'

class HashedUser < HashIt
  def is?( profil )
    # FIXME
    # profils = env['rack.session'][:current_user]['profils']
    LOGGER.debug @info

    profils = @profils
    @info['ENTPersonProfils'].include? "#{profil}:#{profils[0]['uai']}"
  end

  def admin?
    # FIXME
    profil_actif = @info['profils'].select { |p| p['actif'] }.first
    @info['roles']
      .select { |r|
      r['etablissement_code_uai'] == profil_actif['etablissement_code_uai'] &&
        ( r['role_id'] == 'TECH' ||
          r['role_id'].match('ADM.*') )
    }
      .length > 0
  end

  def full( env )
    utilisateur = env['rack.session'][:current_user]

    user_annuaire = @user_detailed # env['rack.session'][:current_user][:user_detailed]

    utilisateur[ 'profils' ] = user_annuaire['profils'].map do |profil|
      # renommage de champs
      profil['type'] = profil['profil_id']
      profil['uai'] = profil['etablissement_code_uai']
      profil['etablissement'] = profil['etablissement_nom']
      profil['nom'] = profil['profil_nom']

      # calcule du droit d'admin, true pour les TECH et les ADM
      profil['admin'] = user_annuaire['roles'].select { |r| r['etablissement_code_uai'] == profil['etablissement_code_uai'] && ( r['role_id'] == 'TECH' || r['role_id'].match('ADM.*') ) }.length > 0

      profil['classes'] = AnnuaireWrapper.get_etablissement_regroupements( profil['uai'] ) if profil['type'] == 'EVS'
      profil
    end
    utilisateur[ 'enfants' ] = user_annuaire [ 'enfants' ]

    utilisateur[ 'classes' ] = user_annuaire[ 'classes' ]
                               .concat( user_annuaire['groupes_eleves'] )
                               .concat( user_annuaire['groupes_libres'] )
                               .map do |regroupement|
      if regroupement.key? 'groupe_id'
        regroupement['type'] = 'groupe'
        regroupement['classe_id'] = regroupement['groupe_id']
        regroupement['classe_libelle'] = regroupement['groupe_libelle']
      else
        regroupement['type'] = 'classe'
      end
      regroupement
    end

    parametres = UserParameters.where( uid: utilisateur[ :uid ] ).first
    parametres = UserParameters.create( uid: utilisateur[ :uid ] ) if parametres.nil?
    parametres.update( date_connexion: Time.now )
    parametres.save

    utilisateur[ 'parametrage_cahier_de_textes' ] = JSON.parse( parametres[:parameters] )

    utilisateur[ 'marqueur_xiti' ] = ''
    utilisateur[ 'marqueur_xiti' ] = '<script>' + RestClient.get( "https://www.laclasse.com/pls/public/xiti_men.get_marqueur_ctv3?plogin=#{utilisateur['user']}" ) + '</script>' if ANNUAIRE[:api_mode] == 'v2'

    utilisateur
  end
end
