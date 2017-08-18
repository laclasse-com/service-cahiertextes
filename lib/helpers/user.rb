require 'net/http'

require 'yaml'

module LaClasse
  module Helpers
    module User
      def user( uid = nil )
        JSON.parse( RestClient::Request.execute( method: :get,
                                                 url: "#{URL_ENT}/api/users/#{uid.nil? ? session['user'] : uid}",
                                                 user: ANNUAIRE[:app_id],
                                                 password: ANNUAIRE[:api_key] ) )
      end

      def user_active_profile( uid = nil )
        user( uid )['profiles'].select { |profile| profile['active'] }.first
      end

      def user_is_profile_in_structure?( profile_type, structure_id, uid = nil )
        !user( uid )['profiles'].select { |profile| profile_type == profile['type'] && structure_id == profile['structure_id'] }.empty?
      end

      def user_needs_to_be( profile_types, uid = nil )
        active_structure = user_active_profile( uid )['structure_id']

        profile_types.reduce( false ) do |memo, profile_type|
          memo || user_is_profile_in_structure?( profile_type, active_structure, uid )
        end
      end

      def user_regroupements_ids( uid = nil )
        if %w[DIR ADM DOC CPE].include?( user_active_profile['type'] )
          JSON.parse( RestClient::Request.execute( method: :get,
                                                   url: "#{URL_ENT}/api/groups/?structure_id=#{user_active_profile['structure_id']}",
                                                   user: ANNUAIRE[:app_id],
                                                   password: ANNUAIRE[:api_key] ) )
              .map { |g| g['id'] }
        else
          user( uid )['groups'].map { |g| g['group_id'] }
        end
      end

      def user_ctxt
        utilisateur = JSON.parse( RestClient::Request.execute( method: :get,
                                                               url: "#{URL_ENT}/api/users/#{session['user']}",
                                                               user: ANNUAIRE[:app_id],
                                                               password: ANNUAIRE[:api_key] ) )

        parametres = UserParameters.where( uid: utilisateur[ 'id' ] ).first
        parametres = UserParameters.create( uid: utilisateur[ 'id' ] ) if parametres.nil?
        parametres.update( date_connexion: Time.now )
        parametres.save

        utilisateur[ 'parametrage_cahier_de_textes' ] = JSON.parse( parametres[:parameters] )

        all_matieres = JSON.parse( RestClient::Request.execute( method: :get,
                                                                url: "#{URL_ENT}/api/subjects",
                                                                user: ANNUAIRE[:app_id],
                                                                password: ANNUAIRE[:api_key] ) )

        utilisateur['enfants'] = utilisateur['children']
        utilisateur[ 'profils' ] = utilisateur['profiles'].map do |profil|
          profil['matieres'] = all_matieres

          profil
        end

        utilisateur
      end
    end
  end
end
