# coding: utf-8
# frozen_string_literal: true

module Routes
    module Api
        module Timeslots
            def self.registered( app )
                app.get '/api/timeslots/?' do
                    # {
                    param 'no_year_restriction', :boolean
                    param 'include_deleted', :boolean
                    param 'date<', Date
                    param 'date>', Date
                    param 'groups_ids', Array
                    param 'subjects_ids', Array
                    param 'structure_id', String
                    param 'import_id', Integer
                    # }

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
                    param 'id', Integer, required: true
                    param 'start_time', Date
                    param 'end_time', Date
                    # }

                    timeslot = Timeslot[ id: params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    json( timeslot.detailed( params['start_time'], params['end_time'], %w[locations sessions assignments] ) )
                end

                app.post '/api/timeslots/?' do
                    # {
                    param 'group_id', Integer
                    param 'subject_id', String
                    param 'weekday', Integer
                    param 'start_time', DateTime
                    param 'end_time', DateTime

                    param 'timeslots', Array

                    one_of :timeslots, :group_id
                    # }

                    user_needs_to_be( %w[ ENS DOC ADM DIR ] )

                    single = !params.key?( 'timeslots' )

                    if single
                        params['timeslots'] = [ { weekday: params['weekday'],
                                                  start_time: params['start_time'],
                                                  end_time: params['end_time'],
                                                  group_id: params['group_id'],
                                                  subject_id: params['subject_id'],
                                                  structure_id: params['structure_id']} ]
                    end

                    result = params['timeslots'].map do |timeslot|
                        new_timeslot = Timeslot.create( ctime: Time.now,
                                                        start_time: timeslot['start_time'],
                                                        end_time: timeslot['end_time'],
                                                        weekday: timeslot['weekday'],
                                                        subject_id: timeslot['subject_id'],
                                                        group_id: timeslot['group_id'],
                                                        structure_id: timeslot['structure_id'] )
                        new_timeslot.modify( timeslot )

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

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    timeslot.modify( params )

                    json( timeslot.to_hash )
                end

                app.delete '/api/timeslots/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'dtime', DateTime, required: true
                    # }

                    user_needs_to_be( %w[ ENS DOC ] )

                    timeslot = Timeslot[ params['id'] ]

                    halt( 404, 'Créneau inconnu' ) if timeslot.nil?

                    timeslot.update( deleted: !timeslot.deleted, dtime: timeslot.deleted ? nil : params['dtime'] )

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

                    json( timeslot.similar( params['groups_ids'], params['start_time'], params['end_time'] ) )
                end
            end
        end
    end
end