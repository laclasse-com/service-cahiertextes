# frozen_string_literal: true

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
        end
    end
end
