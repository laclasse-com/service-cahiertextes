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

                    # FIXME: security

                    result = params['reservations'].map do |reservation|
                        reservation = JSON.parse( reservation ) if reservation.is_a?( String )

                        new_reservation = Reservation.create( timeslot_id: reservation['timeslot_id'],
                                                              resource_id: reservation['resource_id'],
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

                    reservation[:vtime] = params['vtime'] if params.key?( 'vtime' )

                    # FIXME: security

                    if params.key?( 'active_weeks' )
                        reservation[:active_weeks] = params['active_weeks']
                        reservation[:date] = nil
                    elsif params.key?( 'date' )
                        reservation[:date] = params['date']
                        reservation[:active_weeks] = nil
                    end

                    reservation[:timeslot_id] = params['timeslot_id'] if params.key?( 'timeslot_id' )
                    reservation[:resource_id] = params['resource_id'] if params.key?( 'resource_id' )

                    json( reservation )
                end

                app.get '/api/reservations/?' do
                    # {
                    param 'timeslots_ids', Array
                    param 'resources_ids', Array
                    param 'vtime', :boolean

                    any_of 'timeslots_ids', 'resources_ids'
                    # }

                    # FIXME: security

                    query = Reservation

                    query = query.where( timeslot_id: params['timeslots_ids'] ) if params.key?( 'timeslots_ids' )
                    query = query.where( resource_id: params['resources_ids'] ) if params.key?( 'resources_ids' )
                    if params.key?( 'vtime' )
                        if params['vtime']
                            query = query.where( Sequel.~( vtime: nil ) )
                        else
                            query = query.where( vtime: nil )
                        end
                    end

                    json( query.naked.all )
                end

                app.get '/api/reservations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    # FIXME: security

                    reservation = Reservation[ id: params['id'] ]
                    halt( 404 ) if reservation.nil?

                    json( reservation )
                end

                app.delete '/api/reservations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    # FIXME: security

                    reservation = Reservation[ id: params['id'] ]
                    halt( 404 ) if reservation.nil?

                    reservation&.destroy

                    nil
                end
            end
        end
    end
end
