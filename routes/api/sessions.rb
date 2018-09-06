# coding: utf-8
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
                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil? || ( session.deleted && session.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/?' do
                    request.body.rewind
                    body = JSON.parse( request.body.read )

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ body['timeslot_id'] ]
                    halt( 409, 'Créneau invalide' ) if timeslot.nil?

                    session = Session.create( enseignant_id: user['id'],
                                              cahier_de_textes_id: DataManagement::Accessors.create_or_get( CahierDeTextes, regroupement_id: timeslot.regroupement_id ).id,
                                              timeslot_id: timeslot.id,
                                              date_session: body['date_session'].to_s,
                                              date_creation: Time.now,
                                              contenu: '' )

                    session.modifie( body )

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/?' do
                    request.body.rewind
                    body = JSON.parse( request.body.read )

                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.date_validation.nil?

                    session.modifie( body )

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/valide/?' do
                    user_needs_to_be( %w[ DIR ] )

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?

                    session.toggle_validated

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/copie/regroupement/:regroupement_id/timeslot/:timeslot_id/date/:date/?' do
                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnu' ) if session.nil?

                    nouveau_session = session.copie( params['regroupement_id'], params['timeslot_id'], params['date'] )

                    hash = session.to_deep_hash
                    hash[:copie_id] = nouveau_session[:id]

                    json( hash )
                end

                app.delete '/api/sessions/:id/?' do
                    user_needs_to_be( %w[ ENS DOC ] )

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.date_validation.nil?

                    session.toggle_deleted

                    json( session.to_deep_hash )
                end
            end
        end
    end
end
