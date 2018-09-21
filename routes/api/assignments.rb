# coding: utf-8
# frozen_string_literal: true

module Routes
    module Api
        module Assignments
            def self.registered( app )
                app.get '/api/assignments/?' do
                    # {
                    param 'enseignants_ids', Array
                    param 'timeslots_ids', Array
                    param 'groups_ids', Array
                    param 'sessions_ids', Array
                    param 'date_due', Date
                    param 'date_due<', Date
                    param 'date_due>', Date
                    param 'include_deleted', :boolean
                    param 'check_done', :boolean
                    param 'uid', String
                    # }

                    halt( 401, '401 Unauthorized' ) unless !params.key?('uid') || ( user['id'] == params['uid'] ||
                                                                                    !user['children'].find { |child| child['child_id'] == params['uid'] }.nil? )

                    return [] if (!params.key?('groups_ids') || params['groups_ids'].empty?) && (!params.key?('timeslots_ids') || params['timeslots_ids'].empty?)

                    query = Assignment

                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )

                    query = query.where( timeslot_id: Timeslot.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

                    query = query.where( session_id: params['session_ids']) if params.key?( 'session_ids' )

                    query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{Date.parse( params['date_due>'] )}'" ) ) if params.key?( 'date_due>' )

                    query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{Date.parse( params['date_due<'] )}'" ) ) if params.key?( 'date_due<' )

                    query = query.where( Sequel.~( Sequel.qualify( 'assignments', 'deleted' ) ) ) unless params.key?( 'include_deleted')

                    data = query.all.map(&:to_deep_hash)

                    if params.key?('uid') && params.key?('check_done') && params['check_done'] == 'true'
                        data.each do |assignment|
                            dti = AssignmentTodoItem[ assignment_id: assignment[:id], author_id: params['uid'] ]
                            assignment[:rtime] = dti.rtime unless dti.nil?
                            assignment[:done] = !dti.nil?
                        end
                    end

                    json( data )
                end

                app.get '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment = Assignment[ params['id'] ]

                    halt( 404, 'Assignment inconnu' ) if assignment.nil? || ( assignment.deleted && assignment.mtime < UNDELETE_TIME_WINDOW.minutes.ago )

                    hd = assignment.to_deep_hash
                    if params['uid']
                        dti = AssignmentTodoItem[ assignment_id: assignment.id, author_id: user['id'] ]
                        hd[:rtime] = dti.rtime unless dti.nil?
                    end

                    json( hd )
                end

                app.post '/api/assignments/?' do
                    # {
                    param 'timeslot_id', Integer, required: true
                    param 'assignment_type_id', Integer, required: true
                    param 'content', String, required: true
                    param 'date_due', Date, required: true
                    param 'time_estimate', Integer, required: true

                    param 'session_id', Integer, required: false
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['timeslot_id'] ]
                    halt( 409, 'Créneau invalide' ) if timeslot.nil?

                    assignment = Assignment.create( enseignant_id: user['id'],
                                                    assignment_type_id: params['assignment_type_id'],
                                                    timeslot_id: timeslot.id,
                                                    content: params['content'],
                                                    date_due: params['date_due'],
                                                    time_estimate: params['time_estimate'],
                                                    ctime: Time.now )

                    if params['session_id'] && !params['session_id'].nil?
                        assignment.update( session_id: params['session_id'] )
                    else
                        session = Session.where( timeslot_id: timeslot.id )
                                         .where( date_session: params['date_due'] )
                                         .where( deleted: false )
                                         .first
                        if session.nil?
                            session = Session.create( enseignant_id: user['id'],
                                                      timeslot_id: timeslot.id,
                                                      date_session: params['date_due'],
                                                      ctime: Time.now,
                                                      content: '' )
                        end
                        assignment.update( session_id: session.id )
                    end

                    params['author_id'] = user['id']

                    assignment.modify( params )

                    json( assignment.to_deep_hash )
                end

                app.put '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment = Assignment[ params['id'] ]
                    halt( 404, 'Assignment inconnu' ) if assignment.nil?

                    if params.key?( 'done' )
                        user_needs_to_be( %w[ ELV ] )

                        assignment.done_by?( user['id'] ) ? assignment.to_be_done_by!( user['id'] ) : assignment.done_by!( user['id'] )

                        hd = assignment.to_deep_hash
                        dti = AssignmentTodoItem[ assignment_id: assignment.id, author_id: user['id'] ]
                        hd[:rtime] = dti.rtime unless dti.nil?
                        hd[:done] = !dti.nil?

                        json( hd )
                    else
                        user_needs_to_be( %w[ ENS DOC ] )

                        params['enseignant_id'] = user['id']

                        assignment.modify( params )
                    end

                    json( assignment.to_deep_hash )
                end

                app.delete '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    assignment = Assignment[ params['id'] ]

                    assignment.update( deleted: !assignment.deleted, mtime: Time.now )
                    assignment.save

                    json( assignment.to_deep_hash )
                end

                app.post '/api/assignments/:id/copy/session/:session_id/timeslot/:timeslot_id/date_due/:date_due' do
                    # {
                    param 'id', Integer, required: true
                    param 'session_id', Integer, required: true
                    param 'timeslot_id', Integer, required: true
                    param 'date_due', Date, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    assignment = Assignment[ params['id'] ]
                    halt( 404, 'Assignment inconnu' ) if assignment.nil?

                    new_assignment = Assignment.create( session_id: params['session_id'],
                                                        assignment_type_id: assignment.assignment_type_id,
                                                        timeslot_id: params['timeslot_id'],
                                                        content: assignment.content,
                                                        date_due: params['date_due'],
                                                        time_estimate: assignment.time_estimate,
                                                        author_id: assignment.author_id,
                                                        ctime: Time.now )

                    assignment.resources.each do |resource|
                        new_assignment.add_resource( resource )
                    end

                    json( new_assignment.to_deep_hash )
                end
            end
        end
    end
end
