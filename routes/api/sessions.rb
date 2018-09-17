# coding: utf-8
# frozen_string_literal: true

require_relative '../../models/session'

module Routes
    module Api
        module Sessions
            def self.registered( app )
                app.get '/api/sessions/?' do
                    # {
                    param 'enseignants_ids', Array
                    param 'timeslots_ids', Array
                    param 'groups_ids', Array
                    param 'date', Date
                    param 'date<', Date
                    param 'date>', Date
                    # }

                    query = Session

                    query = query.where( enseignant_id: params['enseignants_ids'] ) if params.key?( 'enseignants_ids' )
                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') = '#{Date.parse( params['date'] )}'" ) ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{Date.parse( params['date>'] )}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{Date.parse( params['date<'] )}'" ) ) if params.key?( 'date<' )
                    query = query.where( timeslot_id: Timeslot.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

                    json( query.naked.all )
                end

                app.get '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil? || ( session.deleted && session.mtime < UNDELETE_TIME_WINDOW.minutes.ago )

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/?' do
                    # {
                    param 'timeslot_id', Integer, required: true
                    param 'date', Date, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['timeslot_id'] ]
                    halt( 409, 'Créneau invalide' ) if timeslot.nil?

                    session = Session.create( author_id: user['id'],
                                              timeslot_id: timeslot.id,
                                              date: params['date'].to_s,
                                              ctime: Time.now,
                                              content: '' )

                    session.modify( body )

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.vtime.nil?

                    if params.key?( 'validated' )
                        user_needs_to_be( %w[ DIR ] )

                        session.vtime = session.vtime.nil? ? Time.now : nil

                        session.save
                    else
                        user_needs_to_be( %w[ ENS DOC ] )
                        session.modify( params )
                    end

                    json( session.to_deep_hash )
                end

                app.delete '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.vtime.nil?

                    session.update( deleted: !session.deleted, mtime: Time.now )
                    session.save

                    session.assignments.each do |assignment|
                        if session.deleted
                            assignment.update( deleted: session.deleted, mtime: Time.now )
                        elsif assignment.mtime <= UNDELETE_TIME_WINDOW.minutes.ago
                            assignment.update( deleted: session.deleted, mtime: Time.now )
                        end
                        assignment.save
                    end

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/:id/copy/group/:group_id/timeslot/:timeslot_id/date/:date/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'timeslot_id', Integer, required: true
                    param 'date', Date, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?

                    halt( 403, 'Existing session' ) unless Session.where( timeslot_id: params['timeslot_id'],
                                                                          date: params['date'] ).count.zero?

                    target_session = Session.create( timeslot_id: params['timeslot_id'],
                                                     date: params['date'],
                                                     ctime: Time.now,
                                                     content: session.content,
                                                     enseignant_id: session.enseignant_id )

                    session.resources.each do |resource|
                        target_session.add_resource( resource )
                    end

                    json( target_session.to_deep_hash )
                end
            end
        end
    end
end
