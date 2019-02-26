# frozen_string_literal: true

module Routes
    module Api
        module Events
            def self.registered( app )
                app.post '/api/events/?' do
                    # {
                    param 'events', Array, required: true
                    # [ { ?'author_id', Integer
                    #      'date', Date
                    #      'title', String
                    #      'active_weeks', Integer
                    #      'weekday', Integer
                    #      'start_time', DateTime
                    #      'end_time', DateTime
                    #      'contributors_uids', Array<String> } ]
                    # }

                    result = params['events'].map do |event|
                        event = JSON.parse( event ) if event.is_a?( String )

                        new_timeslot = Timeslot.create( ctime: Time.now,
                                                        start_time: event['start_time'],
                                                        end_time: event['end_time'],
                                                        author_id: get_ctxt_user( user['id'] ).id,
                                                        date: event['date'],
                                                        title: event['title'] )

                        if event.key?( 'contributors_uids' )
                            event['contributors_uids'].each do |contributor_uid|
                                new_timeslot.add_contributor( get_ctxt_user( contributor_uid ) )
                            end
                        end

                        new_timeslot.to_hash
                    end

                    json( result )
                end

                app.put '/api/events/:id/?' do
                    # {
                    param 'id', Integer, required: true

                    param 'contributors_ids', Array
                    param 'title', String
                    param 'date', Date
                    param 'weekday', Integer
                    param 'active_weeks', Integer
                    param 'start_time', DateTime
                    param 'end_time', DateTime

                    any_of :group_id, :subject_id, :weekday, :start_time, :end_time
                    # }

                    event = Timeslot[ params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if event.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    halt( 401, '401 Unauthorized' ) if event.author_id != cuid

                    event.modify( params )

                    json( event.to_hash )
                end

                app.delete '/api/events/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'dtime', DateTime, required: true
                    # }

                    event = Timeslot[ params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if event.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    halt( 401, '401 Unauthorized' ) if event.author_id != cuid && !event.contributors.map(&:id).include?( cuid )

                    event.remove_contributor( User[id: cuid] ) if event.contributors.map(&:id).include?( cuid )
                    event.update( dtime: event.dtime.nil? ? params['dtime'] : nil ) if event.author_id == cuid

                    json( event.to_hash )
                end

                app.get '/api/events/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    event = Timeslot[ id: params['id'] ]
                    halt( 404, 'Créneau inconnu' ) if event.nil?

                    cuid = get_ctxt_user( user['id'] ).id
                    halt( 401, '401 Unauthorized' ) if event.author_id != cuid && !event.contributors.map(&:id).include?( cuid )

                    json( event.detailed( params['start_time'], params['end_time'], %w[resources assignments notes] ) )
                end
            end
        end
    end
end
