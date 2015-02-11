# -*- encoding: utf-8 -*-

module CahierDeTextesApp
  module Helpers
    module User
      def rack_session_current_user
        env['rack.session'][:current_user]
      end

      def user_is_admin_in_etablissement?( uai )
        rack_session_current_user[:user_detailed]['roles']
          .select { |role|
          role['etablissement_code_uai'] == uai &&
            ( role['role_id'] == 'TECH' ||
              role['role_id'].match('ADM.*') )
        }
          .length > 0
      end

      def user_is_a?( profils_ids )
        profils_ids.reduce( true ) { |memo, profil_id|
          memo || rack_session_current_user[:user_detailed]['profil_actif']['profil_type'] == profil_id
        }
      end

      def user_is_admin?
        user_is_admin_in_etablissement?( rack_session_current_user[:user_detailed]['profil_actif']['etablissement_code_uai'] )
      end

      def user_needs_to_be( profils_ids, admin )
        error!( '401 Unauthorized', 401 ) unless ( profils_ids.empty? || user_is_a?( profils_ids ) ) || ( admin && user_is_admin? )
      end

      def user_verbose
        utilisateur = rack_session_current_user

        utilisateur[ 'profils' ] = rack_session_current_user[:user_detailed]['profils'].map do |profil|
          # renommage de champs
          profil['type'] = profil['profil_id']
          profil['uai'] = profil['etablissement_code_uai']
          profil['etablissement'] = profil['etablissement_nom']
          profil['nom'] = profil['profil_nom']

          # calcule du droit d'admin, true pour les TECH et les ADM
          profil['admin'] = user_is_admin_in_etablissement?( profil['etablissement_code_uai'] )

          profil['classes'] = AnnuaireWrapper.get_etablissement_regroupements( profil['uai'] ) if profil['type'] == 'EVS'
          profil
        end
        utilisateur[ 'enfants' ] = rack_session_current_user[:user_detailed] [ 'enfants' ]

        utilisateur[ 'classes' ] = rack_session_current_user[:user_detailed][ 'classes' ]
                                   .concat( rack_session_current_user[:user_detailed]['groupes_eleves'] )
                                   .concat( rack_session_current_user[:user_detailed]['groupes_libres'] )
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

      def user_regroupements_ids( enfant_id = nil )
        LOGGER.debug 'Collecting regroupements IDs'

        case
        when %w( EVS DIR ).include?( rack_session_current_user[:user_detailed]['profil_actif']['profil_id'] )
          LOGGER.debug "from the Etablissement #{rack_session_current_user[:user_detailed]['profil_actif']['etablissement_code_uai']}"

          etablissement = AnnuaireWrapper.get_etablissement( rack_session_current_user[:user_detailed]['profil_actif']['etablissement_code_uai'] )
          LOGGER.debug "#{etablissement}"

          etablissement['classes']
            .concat( etablissement['groupes_eleves'] )
            .concat( etablissement['groupes_libres'] )
            .map { |regroupement| regroupement['id'] }
            .compact
        when %w( TUT ).include?( rack_session_current_user[:user_detailed]['profil_actif']['profil_id'] )
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
          rack_session_current_user[:user_detailed]['classes']
            .concat( rack_session_current_user[:user_detailed]['groupes_eleves'] )
            .concat( rack_session_current_user[:user_detailed]['groupes_libres'] )
            .select { |regroupement| regroupement['etablissement_code'] == rack_session_current_user[:user_detailed]['profil_actif']['etablissement_code_uai'] }
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
