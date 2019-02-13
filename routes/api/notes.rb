# frozen_string_literal: true

require_relative '../../models/note'

module Routes
    module Api
        module Notes
            def self.registered( app )
                app.get '/api/notes/?' do
                    # {
                    param 'timeslots_ids', Array
                    param 'date', Date
                    param 'date>', Date
                    param 'date<', Date

                    any_of 'timeslots_ids', 'date', 'date>', 'date<'
                    # }

                    query = Note.where( author_id: get_ctxt_user( user['id'] ).id )
                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( date: params['date'] ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) ) if params.key?( 'date<' )

                    json( query.naked.all )
                end

                app.get '/api/notes/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    note = Note[ id: params['id'] ]
                    halt( 404, 'Note inconnue' ) if note.nil? || ( !note.dtime.nil? && note.dtime < UNDELETE_TIME_WINDOW.minutes.ago )
                    halt( 401, '401 Unauthorized' ) unless note.author_id == get_ctxt_user( user['id'] ).id

                    json( note )
                end

                app.post '/api/notes/?' do
                    # {
                    param 'notes', Array, require: true
                    # [{ 'timeslot_id', Integer, required: true
                    #    'content', String }]
                    # }

                    author_id = get_ctxt_user( user['id'] ).id

                    result = params['notes'].map do |note|
                        note = JSON.parse( note ) if note.is_a?( String )

                        timeslot = Timeslot[ id: note['timeslot_id'] ]

                        halt( 409, 'Créneau invalide' ) if timeslot.nil?

                        note = Note.create( author_id: author_id,
                                            timeslot_id: timeslot.id,
                                            date: note['date'].to_s,
                                            ctime: Time.now,
                                            content: note['content'] )
                        note.save

                        note
                    end

                    json( result )
                end

                app.put '/api/notes/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'date', Date
                    param 'content', String
                    # }

                    note = Note[ id: params['id'] ]

                    halt( 404, 'Note inconnue' ) if note.nil?

                    halt( 401, '401 Unauthorized' ) unless note.author_id == get_ctxt_user( user['id'] ).id

                    note.update( date: params['date'] ) if params.key?( 'date' )
                    note.update( content: params['content'] ) if params.key?( 'content' )
                    note.update( mtime: Time.now )
                    note.save

                    json( note )
                end

                app.delete '/api/notes/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    note = Note[ id: params['id'] ]
                    halt( 404, 'Note inconnu' ) if note.nil?

                    halt( 401, '401 Unauthorized' ) unless note.author_id == get_ctxt_user( user['id'] ).id

                    note.update( dtime: note.dtime.nil? ? Time.now : nil, mtime: Time.now )
                    note.save

                    json( note )
                end
            end
        end
    end
end
