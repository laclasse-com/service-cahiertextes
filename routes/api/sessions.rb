# frozen_string_literal: true

require_relative '../../models/session'

module Routes
    module Api
        module Sessions
            def self.registered( app )
                app.get '/api/sessions/?' do
                    query = Session

                    query = query.where( enseignant_id: params['enseignants_ids'] ) if params.key?( 'enseignants_ids' )
                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date_session, '%Y-%m-%d') = '#{Date.parse( params['date_session'] )}'" ) ) if params.key?( 'date_session' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date_session, '%Y-%m-%d') >= '#{Date.parse( params['date_session>'] )}'" ) ) if params.key?( 'date_session>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date_session, '%Y-%m-%d') <= '#{Date.parse( params['date_session<'] )}'" ) ) if params.key?( 'date_session<' )
                    query = query.where( timeslot_id: Timeslot.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

                    json( query.naked.all )
                end

                app.get '/api/sessions/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil? || ( session.deleted && session.mtime < UNDELETE_TIME_WINDOW.minutes.ago )

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/?' do
                    # {
                    param :timeslot_id, Integer, required: true
                    param :date, Date, required: true
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
                    param :id, Integer, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.vtime.nil?

                    session.modify( params )

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/valide/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    user_needs_to_be( %w[ DIR ] )

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?

                    session.toggle_validated

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/copy/group/:group_id/timeslot/:timeslot_id/date/:date/?' do
                    # {
                    param :id, Integer, required: true
                    param :group_id, Integer, required: true
                    param :timeslot_id, Integer, required: true
                    param :date, Date, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?

                    new_session = session.copy( params['group_id'], params['timeslot_id'], params['date'] )

                    hash = session.to_deep_hash
                    hash[:copy_id] = new_session[:id]

                    json( hash )
                end

                app.delete '/api/sessions/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.vtime.nil?

                    session.toggle_deleted

                    json( session.to_deep_hash )
                end
            end
        end
    end
end
