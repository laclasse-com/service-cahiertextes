# frozen_string_literal: true

module Routes
    module Api
        module Timeslots
            def self.registered( app )
                app.get '/api/timeslots/?' do
                    # {
                    param 'date<', Date
                    param 'date>', Date
                    param 'groups_ids', Array
                    param 'subjects_ids', Array
                    param 'structure_id', String
                    param 'import_id', Integer

                    param 'no_year_restriction', :boolean
                    param 'include_deleted', :boolean
                    param 'include_sessions_and_assignments', :boolean
                    # }

                    query = Timeslot

                    query = query.where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) ) unless params.key?( 'no_year_restriction' )
                    query = query.where( Sequel.lit( "`dtime` IS NULL OR DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{params['date<']}'" ) ) if params.key?('date<') && !params.key?( 'include_deleted')
                    query = query.where( group_id: params['groups_ids'] ) if params.key?( 'groups_ids' )
                    query = query.where( subject_id: params['subjects_ids'] ) if params.key?( 'subjects_ids' )
                    query = query.where( structure_id: params['structure_id'] ) if params.key?( 'structure_id' )
                    query = query.where( import_id: params['import_id'] ) if params.key?( 'import_id' )

                    data = query.naked.all

                    if params.key?('date<') && params.key?('date>')
                        data = data.select do |timeslot|
                            ( params['date<'] .. params['date>'] )
                                .reduce( true ) do |memo, day|
                                memo && ( day.wday == timeslot[:weekday] && timeslot[:active_weeks][day.cweek] == 1 )
                            end
                        end

                        if params.key?('include_sessions_and_assignments')
                            data = data.map do |timeslot|
                                # FIXME: copy-pasta from sessions/assignments APIs
                                timeslot[:sessions] = Session.where( timeslot_id: timeslot[:id] )
                                                             .where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) )
                                                             .where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) )
                                                             .naked
                                                             .all

                                timeslot[:assignments] = Assignment.where( timeslot_id: timeslot[:id] )
                                                                   .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{params['date>']}'" ) )
                                                                   .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{params['date<']}'" ) )
                                                                   .naked
                                                                   .all

                                timeslot[:notes] = Note.where( timeslot_id: timeslot[:id] )
                                                       .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{params['date>']}'" ) )
                                                       .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{params['date<']}'" ) )
                                                       .naked
                                                       .all

                                # TODO: done marker when relevant
                                timeslot
                            end
                        end
                    end

                    json( data.map do |ts|
                              ts[:start_time] = ts[:start_time].iso8601
                              ts[:end_time] = ts[:end_time].iso8601

                              ts
                          end )
                end

                app.get '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'start_time', Date
                    param 'end_time', Date
                    # }

                    timeslot = Timeslot[ id: params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ELV TUT ENS EVS DOC ADM ], timeslot.structure_id ) && user_is_in_group_g?( timeslot.group_id )

                    json( timeslot.detailed( params['start_time'], params['end_time'], %w[resources sessions assignments notes] ) )
                end

                app.post '/api/timeslots/?' do
                    # {
                    param 'import_id', Integer
                    param 'group_id', Integer
                    param 'subject_id', String
                    param 'structure_id', String
                    param 'weekday', Integer
                    param 'start_time', DateTime
                    param 'end_time', DateTime

                    param 'timeslots', Array

                    one_of :timeslots, :group_id
                    # }

                    single = !params.key?( 'timeslots' )

                    timeslots = if single
                                    [ { "weekday" => params['weekday'],
                                        "start_time" => params['start_time'],
                                        "end_time" => params['end_time'],
                                        "group_id" => params['group_id'],
                                        "subject_id" => params['subject_id'],
                                        "structure_id" => params['structure_id'],
                                        "import_id" => params['import_id'] } ]
                                else
                                    # params['timeslots'] = params['timeslots'].map { |ts| JSON.parse( ts ) }
                                    params['timeslots']
                                end
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ENS DOC ADM ], timeslots.first['structure_id'] )

                    result = timeslots.map do |timeslot|
                        new_timeslot = Timeslot.create( ctime: Time.now,
                                                        start_time: timeslot['start_time'],
                                                        end_time: timeslot['end_time'],
                                                        weekday: timeslot['weekday'],
                                                        subject_id: timeslot['subject_id'],
                                                        group_id: timeslot['group_id'],
                                                        structure_id: timeslot['structure_id'],
                                                        import_id: timeslot['import_id'] )

                        new_timeslot.to_hash
                    end

                    result = result.first if single

                    json( result )
                end

                app.put '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true

                    param 'group_id', Integer
                    param 'subject_id', String
                    param 'weekday', Integer
                    param 'start_time', DateTime
                    param 'end_time', DateTime

                    any_of :group_id, :subject_id, :weekday, :start_time, :end_time
                    # }

                    timeslot = Timeslot[ params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_group_g?( %w[ ENS DOC ], timeslot.group_id ) || user_is_x_in_structure_s?( %w[ ADM ], timeslot.structure_id )

                    timeslot.modify( params )

                    json( timeslot.to_hash )
                end

                app.delete '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'dtime', DateTime, required: true
                    # }

                    timeslot = Timeslot[ params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_group_g?( %w[ ENS DOC ], timeslot.group_id ) || user_is_x_in_structure_s?( %w[ ADM ], timeslot.structure_id )

                    timeslot.update( dtime: timeslot.dtime.nil? ? params['dtime'] : nil )

                    timeslot.save

                    json( timeslot.to_hash )
                end

                app.get '/api/timeslots/:id/similar/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'groups_ids', Array, required: true
                    param 'start_time', Date, required: true
                    param 'end_time', Date, required: true
                    # }

                    timeslot = Timeslot[ id: params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?
                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ENS DOC ADM ], timeslot.structure_id )

                    json( timeslot.similar( params['groups_ids'], params['start_time'], params['end_time'] ) )
                end
            end
        end
    end
end
