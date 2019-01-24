# frozen_string_literal: true

module Routes
    module Api
        module Assignments
            def self.registered( app )
                app.get '/api/assignments/?' do
                    # {
                    param 'authors_ids', Array
                    param 'timeslots_ids', Array
                    param 'groups_ids', Array
                    param 'sessions_ids', Array
                    param 'date_due', Date
                    param 'date_due<', Date
                    param 'date_due>', Date
                    param 'include_deleted', :boolean
                    param 'check_done', :boolean
                    param 'uid', String

                    any_of 'authors_ids', 'timeslots_ids', 'groups_ids', 'sessions_ids'
                    # }

                    halt( 401, '401 Unauthorized' ) unless !params.key?('uid') || ( user['id'] == params['uid'] ||
                                                                                    !user['children'].find { |child| child['child_id'] == params['uid'] }.nil? )

                    query = Assignment
                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( timeslot_id: Timeslot.where( group_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )
                    query = query.where( session_id: params['session_ids']) if params.key?( 'session_ids' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{Date.parse( params['date_due>'] )}'" ) ) if params.key?( 'date_due>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{Date.parse( params['date_due<'] )}'" ) ) if params.key?( 'date_due<' )
                    query = query.where( dtime: nil ) unless params.key?( 'include_deleted')

                    data = query.all.map(&:to_deep_hash)

                    if params.key?('uid') && params.key?('check_done') && params['check_done'] == 'true'
                        data.each do |assignment|
                            dti = AssignmentTodoItem[ assignment_id: assignment[:id], author_id: params['uid'] ]
                            assignment[:rtime] = dti.rtime unless dti.nil?
                            assignment[:done] = !dti.nil?
                        end
                    end

                    # FIXME: rights to see content

                    json( data )
                end

                app.get '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'check_done', :boolean
                    # }

                    assignment = Assignment[ params['id'] ]

                    halt( 404, 'Assignment inconnu' ) if assignment.nil? || ( !assignment.dtime.nil? && assignment.dtime < UNDELETE_TIME_WINDOW.minutes.ago )
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_group_g?( %w[ELV TUT ENS DIR ADM DOC], assignment.session.timeslot.group_id )

                    hd = assignment.to_deep_hash
                    if params.key?('check_done') && params['check_done'] == 'true'
                        dti = AssignmentTodoItem[ assignment_id: assignment.id, author_id: get_ctxt_user( user['id'] ).id ]
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
                    param 'difficulty', Integer

                    param 'session_id', Integer
                    # }

                    timeslot = Timeslot[ params['timeslot_id'] ]
                    halt( 409, 'Créneau invalide' ) if timeslot.nil?
                    halt( 401, '401 Unauthorized' ) unless user_teaches_subject_x_in_group_g?( timeslot.subject_id, timeslot.group_id )

                    if params['session_id'] && !params['session_id'].nil?
                        session_id = params['session_id']
                    else
                        session = Session.where( timeslot_id: timeslot.id )
                                         .where( date: params['date_due'] )
                                         .where( dtime: nil )
                                         .first
                        if session.nil?
                            session = Session.create( author_id: get_ctxt_user( user['id'] ).id,
                                                      timeslot_id: timeslot.id,
                                                      date: params['date_due'],
                                                      ctime: Time.now,
                                                      content: '' )
                        end
                        session_id = session.id
                    end

                    assignment = Assignment.create( author_id: get_ctxt_user( user['id'] ).id,
                                                    assignment_type_id: params['assignment_type_id'],
                                                    timeslot_id: timeslot.id,
                                                    session_id: session_id,
                                                    content: params['content'],
                                                    date_due: params['date_due'],
                                                    time_estimate: params['time_estimate'],
                                                    difficulty: params['difficulty'],
                                                    ctime: Time.now )

                    assignment.modify( params )

                    json( assignment.to_deep_hash )
                end

                app.put '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true

                    param 'timeslot_id', Integer
                    param 'assignment_type_id', Integer
                    param 'content', String
                    param 'date_due', Date
                    param 'time_estimate', Integer
                    param 'session_id', Integer
                    param 'done', :boolean
                    # }

                    assignment = Assignment[ params['id'] ]
                    halt( 404, 'Assignment inconnu' ) if assignment.nil?

                    u_id = get_ctxt_user( user['id'] ).id

                    if params.key?( 'done' )
                        halt( 401, '401 Unauthorized' ) unless user_is_x_in_group_g?( %w[ELV], assignment.session.timeslot.group_id )

                        !params['done'] || assignment.done_by?( u_id ) ? assignment.to_be_done_by!( u_id ) : assignment.done_by!( u_id )

                        hd = assignment.to_deep_hash
                        dti = AssignmentDoneMarker[ assignment_id: assignment.id, author_id: u_id ]
                        hd[:rtime] = dti.rtime unless dti.nil?
                        hd[:done] = !dti.nil?

                        json( hd )
                    else
                        halt( 401, '401 Unauthorized' ) unless assignment.author_id == u_id || user_teaches_subject_x_in_group_g?( assignment.session.timeslot.subject_id, assignment.session.timeslot.group_id )

                        params['author_id'] = u_id

                        assignment.modify( params )
                    end

                    json( assignment.to_deep_hash )
                end

                app.delete '/api/assignments/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment = Assignment[ params['id'] ]
                    halt( 404, 'Assignment inconnu' ) if assignment.nil?
                    halt( 401, '401 Unauthorized' ) unless assignment.author_id == user['id'] || user_teaches_subject_x_in_group_g?( assignment.session.timeslot.subject_id, assignment.session.timeslot.group_id )

                    assignment.update( dtime: assignment.dtime.nil? ? Time.now : nil, mtime: Time.now )
                    assignment.save

                    json( assignment.to_deep_hash )
                end

                app.post '/api/assignments/:id/copy_to/timeslot/:timeslot_id/date_due/:date_due/session/:session_id' do
                    # {
                    param 'id', Integer, required: true
                    param 'timeslot_id', Integer, required: true
                    param 'date_due', Date, required: true
                    param 'session_id', Integer, required: true
                    # }

                    assignment = Assignment[ params['id'] ]
                    halt( 404, 'Assignment inconnu' ) if assignment.nil?
                    halt( 401, '401 Unauthorized' ) unless user_teaches_subject_x_in_group_g?( assignment.session.timeslot.subject_id, assignment.session.timeslot.group_id )
                    halt( 401, '401 Unauthorized' ) unless user_teaches_subject_x_in_group_g?( assignment.session.timeslot.subject_id, Timeslot[id: params['timeslot_id']].group_id )

                    new_assignment = Assignment.create( assignment_type_id: assignment.assignment_type_id,
                                                        timeslot_id: params['timeslot_id'],
                                                        session_id: params['session_id'],
                                                        content: assignment.content,
                                                        date_due: params['date_due'],
                                                        time_estimate: assignment.time_estimate,
                                                        author_id: assignment.author_id,
                                                        ctime: Time.now )

                    assignment.attachments.each do |attachment|
                        new_assignment.add_attachment( attachment )
                    end

                    json( new_assignment.to_deep_hash )
                end
            end
        end
    end
end
