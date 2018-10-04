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

            def user_is_profile_in_structure?( profile_type, structure_id = nil, uid = nil )
                !user( uid )['profiles'].select { |profile| profile_type == profile['type'] && ( structure_id.nil? || structure_id == profile['structure_id'] ) }.empty?
            end

            def user_is_x_in_structure_s?( profile_types, structure_id = nil, uid = nil )
                profile_types.reduce( false ) do |memo, profile_type|
                    memo || user_is_profile_in_structure?( profile_type, structure_id, uid )
                end
            end

            def user_teaches_subject_x_in_group_g?( subject_id, group_id, _uid = nil )
                !user['groups'].nil? && !user['groups'].select { |profile| %w[ENS DOC].include?( profile['type'] ) && profile['group_id'] == group_id && profile['subject_id'] == subject_id }.empty?
            end

            def user_is_in_group_g?( group_id, _uid = nil )
                !user['groups'].nil? && !user['groups'].select { |profile| profile['group_id'] == group_id }.empty?
            end

            def user_is_x_in_group_g?( profile_types, group_id, _uid = nil )
                !user['groups'].nil? && !user['groups'].select { |profile| profile_types.include?( profile['type'] ) && profile['group_id'] == group_id }.empty?
            end

            def user_is_super_admin?( uid = nil )
                !user( uid )['profiles'].select { |profile| profile['type'] == 'TECH' }.empty?
            end
        end
    end
end
