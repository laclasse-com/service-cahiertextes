# frozen_string_literal: true

module Routes
    module Api
        module Statistics
            def self.registered( app )
                app.get '/api/statistics/structures/:structure_id/groups/?' do
                    # {
                    param :structure_id, String, required: true
                    # }

                    # etab = JSON.parse( RestClient::Request.execute( method: :get,
                    #                                                 url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                    #                                                 user: ANNUAIRE[:app_id],
                    #                                                 password: ANNUAIRE[:api_key] ) )

                    # halt( 404, "Établissement #{params['structure_id']} inconnu" ) if etab.nil?

                    # json etab['groups'].map do |group|
                    #     textbook = TextBook[ group_id: group['id'] ]
                    #     textbook = TextBook.create( ctime: Time.now, group_id: group['id'] ) if textbook.nil?
                    #     textbook.statistics
                    # end

                    'FIXME'
                end

                app.get '/api/statistics/structures/:structure_id/groups/:group_id/?' do
                    # {
                    param :structure_id, String, required: true
                    param :group_id, Integer, required: true
                    # }

                    # cahier_de_textes = CahierDeTextes[ regroupement_id: params['group_id'] ]

                    # halt( 404, "Classe #{params['group_id']} inconnue dans l'établissement #{params['structure_id']}" ) if cahier_de_textes.nil?

                    # json cahier_de_textes.statistics.to_hash

                    'FIXME'
                end

                app.get '/api/statistics/structures/:structure_id/teachers/?' do
                    # {
                    param :structure_id, String, required: true
                    # }

                    # teachers = JSON.parse( RestClient::Request.execute( method: :get,
                    #                                                     url: "#{URL_ENT}/api/profiles/?type=ENS&structure_id=#{values[:UAI]}",
                    #                                                     user: ANNUAIRE[:app_id],
                    #                                                     password: ANNUAIRE[:api_key] ) )

                    # halt( 404, "Établissement #{params['structure_id']} inconnu" ) if teachers.nil?

                    # json teachers.map do |author|
                    #     { author_id: author['user_id'],
                    #       classes: sessions_author( author['user_id'] )[:sessions]
                    #           .group_by { |s| s[:group_id] }
                    #           .map do |group_id, group_sessions|
                    #           { group_id: group_id,
                    #             statistics: group_sessions
                    #                 .group_by { |rs| rs[:mois] }
                    #                 .map do |mois, mois_sessions|
                    #                 { month: mois,
                    #                   validated: mois_sessions.count { |s| s[:valide] },
                    #                   filled: mois_sessions.count }
                    #             end }
                    #       end }
                    # end

                    'FIXME'
                end

                app.get '/api/statistics/structures/:structure_id/teachers/:teacher_id/?' do
                    # {
                    param :structure_id, String, required: true
                    param :teacher_id, String, required: true
                    # }

                    # sessions = { author_id: params['teacher_id'],
                    #              sessions: Session.where( author_id: params['teacher_id'] )
                    #                               .where( deleted: false )
                    #                               .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                    #                               .map do |session|
                    #                  assignments = Assignment.where(session_id: session.id)
                    #                                          .where( deleted: false )
                    #                                          .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                    #                                          .all
                    #                  timeslot = Timeslot[session.timeslot_id]

                    #                  { month: session.date.month,
                    #                    group_id: timeslot.group_id,
                    #                    subject_id: timeslot.subject_id,
                    #                    sessions: sessions,
                    #                    assignments: assignments,
                    #                    valide: !session.vtime.nil? }
                    #              end }

                    # sessions[:sessions] = sessions[:sessions].map do |session|
                    #     session[:sessions] = session[:sessions].to_hash
                    #     session[:assignments] = session[:assignments].map(&:to_hash)

                    #     session
                    # end

                    # json( sessions )

                    'FIXME'
                end
            end
        end
    end
end
