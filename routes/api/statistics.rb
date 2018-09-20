# coding: utf-8
# frozen_string_literal: true

module Routes
    module Api
        module Statistics
            def self.registered( app )
                app.get '/api/statistics/structures/:structure_id/groups/?' do
                    # {
                    param 'structure_id', String, required: true
                    # }

                    etab = JSON.parse( RestClient::Request.execute( method: :get,
                                                                    url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                                                                    user: ANNUAIRE[:app_id],
                                                                    password: ANNUAIRE[:api_key] ) )

                    halt( 404, "Établissement #{params['structure_id']} inconnu" ) if etab.nil?

                    result = {}
                    json etab['groups'].each do |group|
                        result[ group['id'] ] = group_stats( group['id'] )
                    end
                end

                app.get '/api/statistics/structures/:structure_id/groups/:group_id/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'group_id', Integer, required: true
                    # }

                    json( group_stats( params['group_id'] ) )
                end

                app.get '/api/statistics/structures/:structure_id/teachers/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'from', Date
                    param 'to', Date
                    param 'groups_ids', Array
                    param 'subjects_ids', Array
                    # }

                    teachers = JSON.parse( RestClient::Request.execute( method: :get,
                                                                        url: "#{URL_ENT}/api/profiles/?type=ENS&structure_id=#{values[:UAI]}",
                                                                        user: ANNUAIRE[:app_id],
                                                                        password: ANNUAIRE[:api_key] ) )

                    halt( 404, "Établissement #{params['structure_id']} inconnu" ) if teachers.nil?

                    result = {}
                    teachers.each do |teacher|
                        stats = teacher_stats( teacher.id,
                                               nil,
                                               params['from'],
                                               params['to'],
                                               params['subjects_ids'],
                                               params['groups_ids'] )

                        result[ teacher.id ] = { validated: stats[:sessions].count { |s| !s.vtime.nil? },
                                                 filled: stats[:sessions].count { |s| s.vtime.nil? } }
                    end

                    json( result )
                end

                app.get '/api/statistics/structures/:structure_id/teachers/:teacher_id/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'teacher_id', String, required: true
                    param 'validated', Boolean
                    param 'from', Date
                    param 'to', Date
                    param 'groups_ids', Array
                    param 'subjects_ids', Array
                    # }

                    json( teacher_stats( params['teacher_id'],
                                         params['validated'],
                                         params['from'],
                                         params['to'],
                                         params['subjects_ids'],
                                         params['groups_ids'] ) )
                end
            end
        end
    end
end
