# frozen_string_literal: true

require_relative '../../models/session'

module Routes
    module Api
        module Sessions
            def self.registered( app )
                app.get '/api/sessions/?' do
                    # {
                    param 'authors_ids', Array
                    param 'timeslots_ids', Array
                    param 'groups_ids', Array
                    param 'date', Date
                    param 'date>', Date
                    param 'date<', Date

                    any_of 'authors_ids', 'timeslots_ids', 'groups_ids', 'date', 'date>', 'date<'
                    # }

                    query = Session

                    query = query.where( author_id: params['authors_ids'] ) if params.key?( 'authors_ids' )
                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( date: params['date'] ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) ) if params.key?( 'date<' )
                    query = query.where( timeslot_id: Timeslot.where( group_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

                    # FIXME: rights to see content

                    json( query.naked.all )
                end

                app.get '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil? || ( !session.dtime.nil? && session.dtime < UNDELETE_TIME_WINDOW.minutes.ago )

                    user_needs_to_be_in_group( %w[ELV TUT ENS DIR ADM DOC], session.timeslot.group_id )

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/?' do
                    # {
                    param 'timeslot_id', Integer, required: true
                    param 'date', Date, required: true
                    param 'content', String
                    # }

                    timeslot = Timeslot[ params['timeslot_id'] ]
                    halt( 409, 'Créneau invalide' ) if timeslot.nil?

                    user_needs_to_teach_subject_in_group( timeslot.subject_id, timeslot.group_id )

                    session = Session.create( author_id: user['id'],
                                              timeslot_id: timeslot.id,
                                              date: params['date'].to_s,
                                              ctime: Time.now,
                                              content: '' )

                    session.modify( params )

                    json( session.to_deep_hash )
                end

                app.put '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'date', Date
                    param 'content', String
                    param 'vtime', DateTime
                    param 'validated', :boolean
                    # }

                    session = Session[ id: params['id'] ]

                    halt( 404, 'Session inconnus' ) if session.nil?

                    if params.key?( 'validated' ) && ( !params['validated'] || params.key?( 'vtime' ) )
                        user_needs_to_be( %w[ DIR ], session.timeslot.structure_id )

                        session.vtime = nil
                        session.vtime = params['vtime'] if params['validated'] && params.key?( 'vtime' )

                        session.save
                    else
                        user_needs_to_teach_subject_in_group( session.timeslot.subject_id, session.timeslot.group_id )

                        halt( 401, 'Session visée non modifiable' ) unless session.vtime.nil?

                        session.modify( params )
                    end

                    json( session.to_deep_hash )
                end

                app.delete '/api/sessions/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 401, 'Session visé non modifiable' ) unless session.vtime.nil?

                    user_needs_to_teach_subject_in_group( session.timeslot.subject_id, session.timeslot.group_id )

                    session.update( dtime: session.dtime.nil? ? Time.now : nil, mtime: Time.now )
                    session.save

                    session.assignments.select { |assignment| !session.dtime.nil? || assignment.dtime <= UNDELETE_TIME_WINDOW.minutes.ago }
                           .each do |assignment|
                        assignment.update( dtime: session.dtime, mtime: Time.now )
                        assignment.save
                    end

                    json( session.to_deep_hash )
                end

                app.post '/api/sessions/:id/copy_to/timeslot/:timeslot_id/date/:date/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'timeslot_id', Integer, required: true
                    param 'date', Date, required: true
                    # }

                    session = Session[ id: params['id'] ]
                    halt( 404, 'Session inconnu' ) if session.nil?
                    halt( 403, 'Existing session' ) unless Session.where( timeslot_id: params['timeslot_id'],
                                                                          date: params['date'] ).count.zero?

                    user_needs_to_teach_subject_in_group( session.timeslot.subject_id, session.timeslot.group_id )
                    user_needs_to_teach_subject_in_group( session.timeslot.subject_id, Timeslot[id: params['timeslot_id']].group_id )

                    target_session = Session.create( timeslot_id: params['timeslot_id'],
                                                     date: params['date'],
                                                     ctime: Time.now,
                                                     content: session.content,
                                                     author_id: session.author_id )

                    session.attachments.each do |attachment|
                        target_session.add_attachment( attachment )
                    end

                    json( target_session.to_deep_hash )
                end
            end
        end
    end
end
