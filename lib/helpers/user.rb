# -*- encoding: utf-8 -*-

module CahierDeTextesApp
  module Helpers
    module User
      def user
        env['rack.session'][:current_user]
      end

      def user_is_admin_in_etablissement?( uai )
        user[:user_detailed]['roles']
          .select { |role|
          role['etablissement_code_uai'] == uai &&
            ( role['role_id'] == 'TECH' ||
              role['role_id'].match('ADM.*') )
        }
          .length > 0
      end

      def user_is_a?( profils_ids )
        profils_ids.reduce( false ) { |memo, profil_id|
          memo || user[:user_detailed]['profil_actif']['profil_id'] == profil_id
        }
      end

      def user_is_admin?
        user_is_admin_in_etablissement?( user[:user_detailed]['profil_actif']['etablissement_code_uai'] )
      end

      def user_belongs_to_profils_or_is_admin?( profils_ids, admin )
        ( profils_ids.empty? && admin && user_is_admin? ) ||
          ( user_is_a?( profils_ids ) || ( admin && user_is_admin? ) )
      end

      def user_needs_to_be( profils_ids, admin )
        error!( '401 Unauthorized', 401 ) unless user_belongs_to_profils_or_is_admin?( profils_ids, admin )
      end

      def user_verbose
        utilisateur = user

        utilisateur[ 'profils' ] = utilisateur[:user_detailed]['profils'].map do |profil|
          # calcule du droit d'admin, true pour les TECH et les ADM
          profil['admin'] = user_is_admin_in_etablissement?( profil['etablissement_code_uai'] )

          profil['classes'] = AnnuaireWrapper.get_etablissement_regroupements( profil['uai'] ) if profil['type'] == 'EVS'
          profil
        end

        utilisateur[ 'profil_actif' ] = user[:user_detailed][ 'profil_actif' ]

        utilisateur[ 'enfants' ] = user[:user_detailed][ 'enfants' ]

        utilisateur[ 'classes' ] = user[:user_detailed][ 'classes' ]
                                   .concat( user[:user_detailed]['groupes_eleves'] )
                                   .concat( user[:user_detailed]['groupes_libres'] )
                                   .map do |regroupement|
          if regroupement.key? 'groupe_id'
            regroupement['type'] = 'groupe'
            regroupement['id'] = regroupement['groupe_id']
            regroupement['libelle'] = regroupement['groupe_libelle']
          else
            regroupement['type'] = 'classe'
            regroupement['id'] = regroupement['classe_id']
            regroupement['libelle'] = regroupement['classe_libelle']
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

        # shaving useless infos
        utilisateur[:user_detailed].delete( 'etablissements' )
        utilisateur[:user_detailed].delete( 'applications' )
        utilisateur[:user_detailed].delete( 'ressources_numeriques' )
        utilisateur[:user_detailed].delete( 'profils' )
        utilisateur[:user_detailed].delete( 'profil_actif' )
        utilisateur[:user_detailed].delete( 'enfants' )
        utilisateur[:user_detailed].delete( 'classes' )
        utilisateur[:user_detailed].delete( 'groupes_eleves' )
        utilisateur[:user_detailed].delete( 'groupes_libres' )
        utilisateur[:user_detailed].delete( 'roles' )

        utilisateur
      end

      def user_regroupements_ids( enfant_id = nil )
        case
        when %w( EVS DIR ).include?( user[:user_detailed]['profil_actif']['profil_id'] )
          etablissement = AnnuaireWrapper.get_etablissement( user[:user_detailed]['profil_actif']['etablissement_code_uai'] )

          etablissement['classes']
            .concat( etablissement['groupes_eleves'] )
            .concat( etablissement['groupes_libres'] )
            .map { |regroupement| regroupement['id'] }
            .compact
        when %w( TUT ).include?( user[:user_detailed]['profil_actif']['profil_id'] )
          [] if enfant_id.nil?

          enfant = AnnuaireWrapper.get_user( enfant_id ) # FIXME: enfant_actif ?

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
          user[:user_detailed]['classes']
            .concat( user[:user_detailed]['groupes_eleves'] )
            .concat( user[:user_detailed]['groupes_libres'] )
            .select { |regroupement| regroupement['etablissement_code'] == user[:user_detailed]['profil_actif']['etablissement_code_uai'] }
            .map { |regroupement|
            regroupement.key?( 'classe_id' ) ? regroupement['classe_id'] : regroupement['groupe_id']
          }
            .compact
        end
      end
    end
  end
end
