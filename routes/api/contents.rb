# frozen_string_literal: true

require_relative '../../models/content'

module Routes
    module Api
        module Contents
            def self.registered( app )
                app.post '/api/contents/?' do
                    # {
                    param 'contents', Array, require: true
                    # }

                    author_id = get_ctxt_user( user['id'] ).id

                    result = params['contents'].map do |content|
                        content = JSON.parse( content ) if content.is_a?( String )

                        timeslot = Timeslot[ id: content['timeslot_id'] ]
                        halt( 409, 'Créneau invalide' ) if timeslot.nil?

                        halt( 401, '401 Unauthorized' ) unless content['type'] == "note" || user_teaches_subject_x_in_group_g?( timeslot.subject_id, timeslot.group_id )

                        if content.key?('trail_id')
                            trail = Trail[ id: content['trail_id'] ]
                            halt( 409, 'Trail invalide' ) if trail.nil?
                        end

                        new_content = Content.create( author_id: author_id,
                                                      type: content['type'],
                                                      timeslot_id: timeslot.id,
                                                      date: content['date'].to_s,
                                                      ctime: Time.now,
                                                      content: content['content'],
                                                      assignment_type: content['assignment_type'],
                                                      load: content['load'],
                                                      parent_content_id: content['parent_content_id'],
                                                      trail_id: content.key?('trail_id') ? trail.id : nil )

                        new_content.save
                        if content.key?('attachments')
                            content['attachments'].each do |attachment|
                                new_content.add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                                                     type: attachment['type'],
                                                                                                     name: attachment['name'],
                                                                                                     external_id: attachment['external_id'] ) )
                            end
                        end

                        new_content
                    end

                    json( result )
                end

                app.put '/api/contents/:id/?' do
                    # {
                    param 'id', Integer, required: true

                    param 'timeslot_id', Integer
                    param 'date', Date
                    param 'vtime', :boolean
                    param 'stime', :boolean
                    param 'atime', DateTime
                    param 'content', String
                    param 'trail_id', Integer
                    param 'parent_content_id', Integer
                    param 'load', Integer
                    param 'assignment_type', String
                    param 'type', String
                    # }

                    content = Content[ id: params['id'] ]

                    halt( 404 ) if content.nil?
                    halt( 401 ) unless ( content.vtime.nil? && content.author_id == get_ctxt_user( user['id'] ).id ) || ( (params.key?('vtime') || params.key?('stime')) && content.type == "session" && user_is_x_in_structure_s?( %w[DIR], content.timeslot.structure_id ) )

                    if content.type == "session" && user_is_x_in_structure_s?( %w[DIR], content.timeslot.structure_id )
                        content.vtime = params['vtime'] ? DateTime.now : nil if params.key?('vtime')
                        content.stime = params['stime'] ? DateTime.now : nil if params.key?('stime')

                        content.mtime = Time.now
                        content.save_changes
                    end
                    if content.vtime.nil? && content.author_id == get_ctxt_user( user['id'] ).id
                        content.type = params['type'] if params.key?( 'type' )
                        content.timeslot_id = params['timeslot_id'] if params.key?( 'timeslot_id' )

                        content.date = params['date'] if params.key?( 'date' )
                        content.atime = params['atime'] if params.key?('atime')
                        content.content = params['content'] if params.key?( 'content' )
                        content.trail_id = params['trail_id'] if params.key?( 'trail_id' )

                        if content.type == "assignment"
                            content.parent_content_id = params['parent_content_id'] if params.key?( 'parent_content_id' )
                            content.load = params['load'] if params.key?( 'load' )
                            content.assignment_type = params['assignment_type'] if params.key?( 'assignment_type' )
                        end

                        content.mtime = Time.now
                        content.save_changes
                    end

                    json( content )
                end

                app.delete '/api/contents/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    content = Content[ id: params['id'] ]
                    halt( 404, 'Content inconnu' ) if content.nil?

                    halt( 401, '401 Unauthorized' ) unless content.author_id == get_ctxt_user( user['id'] ).id

                    content.update( dtime: content.dtime.nil? ? Time.now : nil, mtime: Time.now )

                    content.save_changes

                    json( content )
                end

                app.get '/api/contents/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    content = Content[ id: params['id'] ]
                    halt( 404, 'Content inconnue' ) if content.nil? || ( !content.dtime.nil? && content.dtime < UNDELETE_TIME_WINDOW.minutes.ago )
                    halt( 401, '401 Unauthorized' ) unless content.author_id == get_ctxt_user( user['id'] ).id || user_is_x_in_structure_s?( %w[DIR ENS ELV TUT DOC], content.timeslot.structure_id )

                    json( content )
                end

                app.get '/api/contents/?' do
                    # {
                    param 'timeslots_ids', Array
                    param 'authors_ids', Array
                    param 'trails_ids', Array
                    param 'parent_contents_ids', Array
                    param 'assignment_types', Array
                    param 'types', Array
                    param 'date', Date
                    param 'date>', Date
                    param 'date<', Date
                    # }

                    query = Content

                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( type: params['types'] ) if params.key?('types')
                    query = query.where( date: params['date'] ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) ) if params.key?( 'date<' )
                    query = query.where( author_id: params['authors_ids']) if params.key?( 'authors_ids' )
                    query = query.where( trail_id: params['trails_ids']) if params.key?( 'trails_ids' )
                    query = query.where( parent_content_id: params['parent_contents_ids']) if params.key?( 'parent_contents_ids' )
                    query = query.where( assignment_type: params['assignment_types'] ) if params.key?('assignment_types')

                    json( query.naked.all )
                end
            end
        end
    end
end
