# coding: utf-8

module Routes
    module Api
        module Timeslots
            def self.registered( app )
                app.get '/api/timeslots/?' do
                    query = Timeslot

                    query = query.where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) ) unless params.key?( 'no_year_restriction' )
                    query = query.where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{Date.parse( params['date<'] )}')" ) ) if params.key?('date<') && !params.key?( 'include_deleted')
                    query = query.where( group_id: params['groups_ids'] ) if params.key?( 'groups_ids' )
                    query = query.where( subject_id: params['subjects_ids'] ) if params.key?( 'subjects_ids' )
                    query = query.where( structure_id: params['structure_id'] ) if params.key?( 'structure_id' )
                    query = query.where( import_id: params['import_id'] ) if params.key?( 'import_id' )

                    data = query.naked.all

                    if params.key?('date<') && params.key?('date>')
                        data = data.select do |timeslot|
                            ( (Date.parse(params['date>']) .. Date.parse(params['date<'])).reduce(true) { |memo, day| memo && (day.wday == timeslot.weekday && timeslot.active_weeks[day.cweek] == 1) } )
                        end
                    end

                    json( data )
                end

                app.get '/api/timeslots/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    timeslot = Timeslot[ id: params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    json( timeslot.detailed( params['start'], params['end'], %w[locations sessions assignments] ) )
                end

                app.get '/api/timeslots/:id/similar/?' do
                    # {
                    param :id, Integer, required: true
                    param :groups_ids, Array, required: true
                    param :start, Date, required: true
                    param :end, Date, required: true
                    # }

                    timeslot = Timeslot[ id: params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    json( timeslot.similar( params['groups_ids'], params['start'], params['end'] ) )
                end

                app.post '/api/timeslots/?' do
                    # {
                    param :group_id, Integer, required: true
                    param :subject_id, Integer, required: true
                    param :weekday, Integer, required: true
                    param :start, Date, required: true
                    param :end, Date, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    structure = DataManagement::Accessors.create_or_get( Structure,
                                                                         UAI: user_active_profile['structure_id'] )

                    timeslot = Timeslot.create( ctime: Time.now,
                                                start: params['start'],
                                                end: params['end'],
                                                weekday: params['weekday'].to_i - 1,
                                                subject_id: params['subject_id'],
                                                group_id: params['group_id'],
                                                structure_id: structure.id )

                    timeslot.modify( params )

                    json( timeslot.to_hash )
                end

                app.post '/api/timeslots/bulk/?' do
                    # {
                    param :timeslots, Array, required: true
                    # }

                    structure = DataManagement::Accessors.create_or_get( Structure,
                                                                         UAI: params['uai'] )

                    json( params['timeslots'].map do |timeslot|
                              new_timeslot = Timeslot.create( ctime: Time.now,
                                                              start: timeslot['start'],
                                                              end: timeslot['end'],
                                                              weekday: timeslot['weekday'] - 1,
                                                              subject_id: timeslot['subject_id'],
                                                              group_id: timeslot['group_id'],
                                                              structure_id: structure.id )
                              new_timeslot.modify( timeslot )

                              new_timeslot.to_hash
                          end )
                end

                app.put '/api/timeslots/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    timeslot.modify( params )

                    json( timeslot.to_hash )
                end

                app.delete '/api/timeslots/:id/?' do
                    # {
                    param :id, Integer, required: true
                    param :dtime, DateTime, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    if timeslot.subject_id.empty? && timeslot.sessions.empty? && timeslot.assignments.empty?
                        timeslot.deep_destroy
                    else
                        timeslot.toggle_deleted( params['dtime'] )
                    end

                    json( timeslot.to_hash )
                end
            end
        end
    end
end
