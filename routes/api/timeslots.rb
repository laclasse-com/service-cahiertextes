# frozen_string_literal: true

module Routes
    module Api
        module Timeslots
            def self.registered( app )
                app.post '/api/timeslots/?' do
                    # {
                    param 'timeslots', Array, required: true
                    # }

                    user_id = get_ctxt_user( user['id'] ).id

                    first_pass = params['timeslots'].map do |timeslot|
                        timeslot = JSON.parse( timeslot ) if timeslot.is_a?( String )

                        halt( 401 ) unless timeslot['author_id'].to_i == user_id

                        failed = ( timeslot.key?('group_id') &&
                                   !user_teaches_subject_x_in_group_g?( timeslot['subject_id'], timeslot['group_id'].to_i ) ) ||
                                 ( timeslot.key?('structure_id') &&
                                   !user_is_x_in_structure_s?( %w[ ENS DOC ADM ], timeslot['structure_id'] ) )
                        halt( 401 ) if failed

                        timeslot
                    end
                    result = first_pass.map do |timeslot|
                        new_timeslot = Timeslot.create( ctime: Time.now,
                                                        start_time: timeslot['start_time'],
                                                        end_time: timeslot['end_time'],
                                                        weekday: timeslot['weekday'],
                                                        active_weeks: timeslot['active_weeks'],
                                                        subject_id: timeslot['subject_id'],
                                                        group_id: timeslot['group_id'],
                                                        structure_id: timeslot['structure_id'],
                                                        import_id: timeslot['import_id'],
                                                        author_id: timeslot['author_id'],
                                                        date: timeslot['date'],
                                                        title: timeslot['title'] )

                        if timeslot.key?( 'contributors_uids' )
                            timeslot['contributors_uids'].each do |contributor_uid|
                                new_timeslot.add_contributor( get_ctxt_user( contributor_uid ) )
                            end
                        end

                        new_timeslot.to_hash
                    end

                    json( result )
                end

                app.put '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true

                    param 'group_id', Integer
                    param 'subject_id', String
                    param 'weekday', Integer
                    param 'active_weeks', Integer
                    param 'start_time', DateTime
                    param 'end_time', DateTime
                    param 'date', Date
                    param 'title', String
                    any_of :group_id, :subject_id, :weekday, :start_time, :end_time
                    # }

                    timeslot = Timeslot[ params['id'] ]
                    halt( 404 ) if timeslot.nil?
                    halt( 401 ) unless user_is_x_in_group_g?( %w[ ENS DOC ], timeslot.group_id ) || user_is_x_in_structure_s?( %w[ ADM ], timeslot.structure_id )

                    timeslot.modify( params )

                    json( timeslot.to_hash )
                end

                app.delete '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'dtime', DateTime, required: true
                    # }

                    timeslot = Timeslot[ params['id'] ]
                    halt( 404 ) if timeslot.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    is_author = timeslot.author_id == cuid
                    is_contributor = timeslot.contributors.map(&:id).include?( cuid )
                    teach_in_group = user_teaches_subject_x_in_group_g?( timeslot.subject_id, timeslot.group_id )
                    is_adm = user_is_x_in_structure_s?( %w[ ADM ], timeslot.structure_id )

                    halt( 401 ) unless is_author || is_contributor || teach_in_group || is_adm

                    if is_contributor
                        timeslot.remove_contributor( User[id: cuid] )
                    elsif is_author || teach_in_group || is_adm
                        timeslot.update( dtime: timeslot.dtime.nil? ? params['dtime'] : nil )
                    end

                    json( timeslot.to_hash )
                end

                app.get '/api/timeslots/?' do
                    # {
                    param 'date<', Date
                    param 'date>', Date
                    param 'groups_ids', Array
                    param 'no_groups', :boolean
                    param 'structures_ids', Array
                    param 'no_structures', :boolean
                    param 'subjects_ids', Array
                    param 'import_id', Integer
                    param 'author_id', Integer

                    param 'no_year_restriction', :boolean
                    param 'include_deleted', :boolean
                    # }

                    query = Timeslot
                    if params.key?( 'author_id' )
                        halt( 401 ) unless params['author_id'] == user_id
                        query = query.where( author_id: params['author_id'] )
                    end

                    query = query.where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) ) unless params.key?( 'no_year_restriction' )
                    query = query.where( Sequel.lit( "`dtime` IS NULL OR DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{params['date<']}'" ) ) if params.key?( 'date<' ) && !params.key?( 'include_deleted' )

                    query = query.where( group_id: params['groups_ids'] ) if params.key?( 'groups_ids' ) && ( !params.key?( 'no_groups' ) || ( params.key?( 'no_groups' ) && !params['no_groups'] ) )
                    query = query.where( group_id: nil ) if params.key?( 'no_groups' ) && params['no_groups']

                    query = query.where( structure_id: params['structures_ids'] ) if params.key?( 'structures_ids' ) && ( !params.key?( 'no_structures' ) || ( params.key?( 'no_structures' ) && !params['no_structures'] ) )
                    query = query.where( structure_id: nil ) if params.key?( 'no_structures' ) && params['no_structures']

                    query = query.where( subject_id: params['subjects_ids'] ) if params.key?( 'subjects_ids' )
                    query = query.where( import_id: params['import_id'] ) if params.key?( 'import_id' )

                    data = query.naked.all

                    if params.key?('date<') && params.key?('date>')
                        data = data.select do |timeslot|
                            ( params['date<'] .. params['date>'] )
                                .reduce( true ) do |memo, day|
                                memo && ( day.wday == timeslot[:weekday] && timeslot[:active_weeks][day.cweek] == 1 )
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
                    halt( 404 ) if timeslot.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    halt( 401 ) unless timeslot.author_id == cuid || ( user_is_x_in_structure_s?( %w[ ELV TUT ENS EVS DOC ADM ], timeslot.structure_id ) && user_is_in_group_g?( timeslot.group_id ) )

                    json( timeslot.detailed( params['start_time'], params['end_time'], %w[resources sessions assignments notes] ) )
                end

                app.get '/api/timeslots/:id/similar/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'groups_ids', Array, required: true
                    param 'start_time', Date, required: true
                    param 'end_time', Date, required: true
                    # }

                    timeslot = Timeslot[ id: params['id'] ]
                    halt( 404 ) if timeslot.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    halt( 401 ) unless timeslot.author_id == cuid || user_is_x_in_structure_s?( %w[ ENS DOC ADM ], timeslot.structure_id )

                    json( timeslot.similar( params['groups_ids'], params['start_time'], params['end_time'] ) )
                end
            end
        end
    end
end
