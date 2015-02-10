# encoding: utf-8

require_relative './hash_it'

class HashedUser < HashIt
  def is?( profil )
    @info['ENTPersonProfils'].include? "#{profil}:#{@user_detailed['profils'][0]['uai']}"
  end

  def admin?
    @user_detailed['roles']
      .select { |role|
      role['etablissement_code_uai'] == @user_detailed['profil_actif']['etablissement_code_uai'] &&
        ( role['role_id'] == 'TECH' ||
          role['role_id'].match('ADM.*') )
    }
      .length > 0
  end

  def regroupements_ids( enfant_id = nil )
    LOGGER.debug 'Collecting regroupements IDs'

    case
    when %w( EVS DIR ).include?( @user_detailed['profil_actif']['profil_id'] )
      LOGGER.debug "from the Etablissement #{@user_detailed['profil_actif']['etablissement_code_uai']}"

      etablissement = AnnuaireWrapper.get_etablissement( @user_detailed['profil_actif']['etablissement_code_uai'] )
      LOGGER.debug "#{etablissement}"

      etablissement['classes']
        .concat( etablissement['groupes_eleves'] )
        .concat( etablissement['groupes_libres'] )
        .map { |regroupement| regroupement['id'] }
        .compact
    when %w( TUT ).include?( @user_detailed['profil_actif']['profil_id'] )
      LOGGER.debug "from children #{enfant_id}"
      [] if enfant_id.nil?

      enfant = AnnuaireWrapper.get_user( enfant_id ) # FIXME: enfant_actif ?
      LOGGER.debug "#{enfant}"

      enfant['classes']
        .concat( enfant['groupes_eleves'] )
        .concat( enfant['groupes_libres'] )
        .select { |regroupement| regroupement['etablissement_code'] == enfant['profil_actif']['uai'] }
        .map { |regroupement|
        regroupement['classe_id'] if regroupement.key? 'classe_id'
        regroupement['groupe_id'] if regroupement.key? 'groupe_id'
      }
        .compact
    else
      LOGGER.debug 'from user profile'
      @user_detailed['classes']
        .concat( @user_detailed['groupes_eleves'] )
        .concat( @user_detailed['groupes_libres'] )
        .select { |regroupement| regroupement['etablissement_code'] == @user_detailed['profil_actif']['uai'] }
        .map { |regroupement|
        regroupement['classe_id'] if regroupement.key? 'classe_id'
        regroupement['groupe_id'] if regroupement.key? 'groupe_id'
      }
        .compact
    end
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
