# -*- encoding: utf-8 -*-

module CahierDeTextesApp
  module Helpers
    module User
      def user_verbose
        utilisateur = env['rack.session'][:current_user]

        utilisateur[ 'profils' ] = env['rack.session'][:current_user][:user_detailed]['profils'].map do |profil|
          # renommage de champs
          profil['type'] = profil['profil_id']
          profil['uai'] = profil['etablissement_code_uai']
          profil['etablissement'] = profil['etablissement_nom']
          profil['nom'] = profil['profil_nom']

          # calcule du droit d'admin, true pour les TECH et les ADM
          profil['admin'] = env['rack.session'][:current_user][:user_detailed]['roles'].select { |r| r['etablissement_code_uai'] == profil['etablissement_code_uai'] && ( r['role_id'] == 'TECH' || r['role_id'].match('ADM.*') ) }.length > 0

          profil['classes'] = AnnuaireWrapper.get_etablissement_regroupements( profil['uai'] ) if profil['type'] == 'EVS'
          profil
        end
        utilisateur[ 'enfants' ] = env['rack.session'][:current_user][:user_detailed] [ 'enfants' ]

        utilisateur[ 'classes' ] = env['rack.session'][:current_user][:user_detailed][ 'classes' ]
                                   .concat( env['rack.session'][:current_user][:user_detailed]['groupes_eleves'] )
                                   .concat( env['rack.session'][:current_user][:user_detailed]['groupes_libres'] )
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

      def user_is_a?( profil )
        env['rack.session'][:current_user][:info]['ENTPersonProfils'].include? "#{profil}:#{env['rack.session'][:current_user][:user_detailed]['profils'][0]['uai']}"
      end

      def user_is_admin?
        env['rack.session'][:current_user][:user_detailed]['roles']
          .select { |role|
          role['etablissement_code_uai'] == env['rack.session'][:current_user][:user_detailed]['profil_actif']['etablissement_code_uai'] &&
            ( role['role_id'] == 'TECH' ||
              role['role_id'].match('ADM.*') )
        }
          .length > 0
      end

      def user_regroupements_ids( enfant_id = nil )
        LOGGER.debug 'Collecting regroupements IDs'

        case
        when %w( EVS DIR ).include?( env['rack.session'][:current_user][:user_detailed]['profil_actif']['profil_id'] )
          LOGGER.debug "from the Etablissement #{env['rack.session'][:current_user][:user_detailed]['profil_actif']['etablissement_code_uai']}"

          etablissement = AnnuaireWrapper.get_etablissement( env['rack.session'][:current_user][:user_detailed]['profil_actif']['etablissement_code_uai'] )
          LOGGER.debug "#{etablissement}"

          etablissement['classes']
            .concat( etablissement['groupes_eleves'] )
            .concat( etablissement['groupes_libres'] )
            .map { |regroupement| regroupement['id'] }
            .compact
        when %w( TUT ).include?( env['rack.session'][:current_user][:user_detailed]['profil_actif']['profil_id'] )
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
          env['rack.session'][:current_user][:user_detailed]['classes']
            .concat( env['rack.session'][:current_user][:user_detailed]['groupes_eleves'] )
            .concat( env['rack.session'][:current_user][:user_detailed]['groupes_libres'] )
            .select { |regroupement| regroupement['etablissement_code'] == env['rack.session'][:current_user][:user_detailed]['profil_actif']['uai'] }
            .map { |regroupement|
            regroupement['classe_id'] if regroupement.key? 'classe_id'
            regroupement['groupe_id'] if regroupement.key? 'groupe_id'
          }
            .compact
        end
      end
    end
  end
end
