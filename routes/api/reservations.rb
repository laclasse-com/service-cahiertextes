# frozen_string_literal: true

module Routes
    module Api
        module Reservations
            def self.registered( app )
                app.post '/api/reservations/?' do
                    # {
                    param 'reservations', Array, required: true
                    # }

                    author_id = get_ctxt_user( user['id'] ).id

                    params['reservations'] = params['reservations'].map { |reservation| JSON.parse( reservation ) } if params['reservations'].first.is_a?( String )

                    first_pass = params['reservations'].map do |reservation|
                        reservation[:timeslot] = Timeslot[ id: reservation['timeslot_id'] ]
                        halt( 409 ) if reservation['timeslot'].nil?

                        reservation[:resource] = Resource[ id: reservation['resource_id'] ]
                        halt( 409 ) unless reservation['timeslot']&.structure_id == reservation['resource']&.structure_id

                        halt( 401 ) if reservation.key?('vtime') && reservation['vtime'] &&
                                       !user_is_profile_in_structure?( %w[ADM], reservation['timeslot'].structure_id )

                        if reservation['timeslot'].group_id.nil?
                            halt( 401 ) unless reservation['timeslot'].author_id == get_ctxt_user( user['id'] ).id
                        else
                            halt( 401 ) unless user_is_x_in_group_g?( %w[ENS DOC], reservation['timeslot'].group_id ) ||
                                               user_is_profile_in_structure?( %w[ADM], reservation['timeslot'].structure_id )
                        end

                        reservation
                    end

                    result = first_pass.map do |reservation|
                        new_reservation = Reservation.create( timeslot_id: reservation[:timeslot].id,
                                                              resource_id: reservation[:resource].id,
                                                              active_weeks: reservation['active_weeks'],
                                                              date: reservation['date'],
                                                              vtime: reservation.key?('vtime') && reservation['vtime'] ? DateTime.now : nil,
                                                              author_id: author_id )

                        new_reservation.to_hash
                    end

                    json( result )
                end

                app.put '/api/reservations/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'vtime', :boolean
                    param 'date', Date
                    param 'active_weeks', Integer
                    param 'timeslot_id', Integer
                    param 'resource_id', Integer
                    # }

                    reservation = Reservation[ id: params['id'] ]
                    halt( 404 ) if reservation.nil?

                    if reservation.timeslot.group_id.nil?
                        halt( 401 ) unless reservation.author_id == get_ctxt_user( user['id'] ).id
                    else
                        halt( 401 ) unless user_is_x_in_group_g?( %w[ENS DOC], reservation.timeslot.group_id ) ||
                                           user_is_profile_in_structure?( %w[ADM], reservation.timeslot.structure_id )
                    end

                    if params.key?('timeslot_id')
                        timeslot = Timeslot[ id: params['timeslot_id'] ]
                        halt( 409 ) if timeslot.nil?
                        halt( 401 ) unless ( !timeslot.group_id.nil? && user_is_in_group_g?( timeslot.group_id ) ) ||
                                           ( timeslot.group_id.nil? && timeslot.contributors.include?( user_id ) ) ||
                                           user_is_profile_in_structure?( %w[ADM], timeslot.structure_id )
                    else
                        timeslot = reservation.timeslot
                    end
                    if params.key?('resource_id')
                        resource = Resource[ id: params['resource_id'] ]
                        halt( 409 ) if timeslot&.structure_id != resource&.structure_id
                    end

                    if params.key?( 'vtime' )
                        halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], reservation.resource.structure_id )
                        reservation[:vtime] = params['vtime']
                    end

                    if params.key?( 'active_weeks' )
                        reservation[:active_weeks] = params['active_weeks']
                        reservation[:date] = nil
                    elsif params.key?( 'date' )
                        reservation[:active_weeks] = nil
                        reservation[:date] = params['date']
                    end

                    reservation[:timeslot_id] = timeslot.id if params.key?( 'timeslot_id' )
                    reservation[:resource_id] = resource.id if params.key?( 'resource_id' )

                    json( reservation )
                end

                app.get '/api/reservations/?' do
                    # {
                    param 'timeslots_ids', Array
                    param 'resources_ids', Array
                    param 'vtime', :boolean

                    any_of 'timeslots_ids', 'resources_ids'
                    # }

                    query = Reservation

                    query = query.where( timeslot_id: params['timeslots_ids'] ) if params.key?( 'timeslots_ids' )
                    query = query.where( resource_id: params['resources_ids'] ) if params.key?( 'resources_ids' )
                    if params.key?( 'vtime' )
                        query = if params['vtime']
                                    query.where( Sequel.~( vtime: nil ) )
                                else
                                    query.where( vtime: nil )
                                end
                    end

                    user_id = get_ctxt_user( user['id'] ).id
                    result = query.all.map do |reservation|
                        halt( 401 ) unless reservation.author_id == user_id ||
                                           ( !reservation.timeslot.group_id.nil? && user_is_in_group_g?( reservation.timeslot.group_id ) ) ||
                                           ( reservation.timeslot.group_id.nil? && reservation.timeslot.contributors.include?( user_id ) ) ||
                                           user_is_profile_in_structure?( %w[ADM], reservation.timeslot.structure_id )
                        reservation
                    end

                    json( result.map(&:to_hash) )
                end

                app.get '/api/reservations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    reservation = Reservation[ id: params['id'] ]
                    halt( 404 ) if reservation.nil?

                    timeslot = Timeslot[ id: reservation.timeslot_id ]
                    user_id = get_ctxt_user( user['id'] ).id
                    halt( 401 ) unless reservation.author_id == user_id ||
                                       ( !timeslot.group_id.nil? && user_is_in_group_g?( timeslot.group_id ) ) ||
                                       ( timeslot.group_id.nil? && timeslot.contributors.include?( user_id ) ) ||
                                       user_is_profile_in_structure?( %w[ADM], timeslot.structure_id )

                    json( reservation )
                end

                app.delete '/api/reservations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    reservation = Reservation[ id: params['id'] ]
                    halt( 404 ) if reservation.nil?

                    timeslot = Timeslot[ id: reservation.timeslot_id ]
                    halt( 401 ) unless reservation.author_id == get_ctxt_user( user['id'] ).id ||
                                       user_is_profile_in_structure?( %w[ADM], timeslot.structure_id )

                    reservation&.destroy

                    nil
                end
            end
        end
    end
end
