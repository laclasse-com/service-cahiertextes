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

                    user_id = get_ctxt_user( user['id'] ).id

                    first_pass = params['contents'].map do |content|
                        content = JSON.parse( content ) if content.is_a?( String )

                        halt( 401 ) unless content['author_id'].to_i == user_id

                        content[:timeslot] = Timeslot[ id: content['timeslot_id'] ]
                        halt( 409 ) if content[:timeslot].nil?

                        halt( 401 ) unless content['type'] == "note" || user_teaches_subject_x_in_group_g?( content[:timeslot].subject_id, content[:timeslot].group_id )

                        if content.key?('trails_ids')
                            content[:trails] = content['trails_ids'].map do |trail_id|
                                trail = Trail[ id: trail_id ]
                                halt( 409 ) if trail.nil?

                                trail
                            end
                        end

                        content
                    end
                    result = first_pass.map do |content|
                        new_content = Content.create( author_id: content['author_id'].to_i,
                                                      type: content['type'],
                                                      timeslot_id: content[:timeslot].id,
                                                      date: content['date'].to_s,
                                                      ctime: Time.now,
                                                      content: content['content'],
                                                      assignment_type: content['assignment_type'],
                                                      load: content['load'],
                                                      starred: content.key?('starred') ? content['starred'] == "true" : false,
                                                      parent_content_id: content['parent_content_id'] )

                        new_content.save_changes
                        if content.key?('attachments')
                            content['attachments'].each do |attachment|
                                new_content.add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                                                     type: attachment['type'],
                                                                                                     name: attachment['name'],
                                                                                                     external_id: attachment['external_id'] ) )
                            end
                        end

                        if content.key?(:trails)
                            content[:trails].each do |trail|
                                new_content.add_trail( trail )
                            end
                        end

                        if content.key?('users_ids')
                            content['users_ids'].each do |u_id|
                                new_content.add_user( get_ctxt_user( u_id ) )
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
                    param 'trails_ids', Array
                    param 'parent_content_id', Integer
                    param 'load', Integer
                    param 'assignment_type', String
                    param 'type', String
                    param 'attachments', Array
                    param 'users', Array
                    param 'starred', :boolean
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
                        if params.key?('trails_ids')
                            params[:trails] = params['trails_ids'].map do |trail_id|
                                trail = Trail[ id: trail_id ]
                                halt( 409 ) if trail.nil?

                                trail
                            end
                        end

                        if params.key?(:trails)
                            content.remove_all_trails

                            params[:trails].each do |trail|
                                content.add_trail( trail )
                            end
                        end

                        content.type = params['type'] if params.key?( 'type' )
                        content.timeslot_id = params['timeslot_id'] if params.key?( 'timeslot_id' )

                        content.date = params['date'] if params.key?( 'date' )
                        content.atime = params['atime'] if params.key?('atime')
                        content.content = params['content'] if params.key?( 'content' )
                        content.trail_id = params['trail_id'] if params.key?( 'trail_id' )
                        content.starred = params['starred'] if params.key?( 'starred' )

                        if content.type == "assignment"
                            content.parent_content_id = params['parent_content_id'] if params.key?( 'parent_content_id' )
                            content.load = params['load'] if params.key?( 'load' )
                            content.assignment_type = params['assignment_type'] if params.key?( 'assignment_type' )
                        end

                        if params.key?('attachments')
                            params['attachments'].each do |attachment|
                                content.add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                                                 type: attachment['type'],
                                                                                                 name: attachment['name'],
                                                                                                 external_id: attachment['external_id'] ) )
                            end
                        end

                        if params.key?('users_ids')
                            params['users_ids'].each do |user_id|
                                content.add_user( get_ctxt_user( user_id ) )
                            end
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
                    halt( 404 ) if content.nil?

                    halt( 401 ) unless content.author_id == get_ctxt_user( user['id'] ).id

                    content.update( dtime: content.dtime.nil? ? Time.now : nil, mtime: Time.now )

                    content.save_changes

                    json( content )
                end

                app.get '/api/contents/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    content = Content[ id: params['id'] ]
                    halt( 404 ) if content.nil? || ( !content.dtime.nil? && content.dtime < UNDELETE_TIME_WINDOW.minutes.ago )
                    halt( 401 ) unless content.author_id == get_ctxt_user( user['id'] ).id || user_is_x_in_structure_s?( %w[DIR ENS ELV TUT DOC], content.timeslot.structure_id )

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
                    param 'starred', :boolean
                    # }

                    query = Content

                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( type: params['types'] ) if params.key?('types')
                    query = query.where( date: params['date'] ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) ) if params.key?( 'date<' )
                    query = query.where( author_id: params['authors_ids']) if params.key?( 'authors_ids' )
                    query = query.where( parent_content_id: params['parent_contents_ids']) if params.key?( 'parent_contents_ids' )
                    query = query.where( assignment_type: params['assignment_types'] ) if params.key?('assignment_types')
                    query = query.where( starred: params['starred'] ) if params.key?('starred')
                    query = query.where(id: ContentTrail.where(trail_id: params['trails_ids'] ).select(:content_id) ) if params.key?( 'trails_ids' )

                    json( query.naked.all )
                end
            end
        end
    end
end
