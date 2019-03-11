# frozen_string_literal: true

require_relative '../../models/content'

module Routes
    module Api
        module Contents
            def self.registered( app )
                app.get '/api/contents/?' do
                    # {
                    param 'type', String, in: %w[note session assignment], required: true

                    param 'timeslots_ids', Array
                    param 'groups_ids', Array
                    param 'date', Date
                    param 'date>', Date
                    param 'date<', Date

                    any_of 'timeslots_ids', 'date', 'date>', 'date<'
                    # }
                    query = Content.where( type: params['type'] )
                    # query = query.where( author_id: get_ctxt_user( user['id'] ).id ) if params['type'] == 'note'

                    query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )
                    query = query.where( date: params['date'] ) if params.key?( 'date' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{params['date>']}'" ) ) if params.key?( 'date>' )
                    query = query.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{params['date<']}'" ) ) if params.key?( 'date<' )
                    query = query.where( timeslot_id: Timeslot.where( group_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

                    json( query.naked.all )
                end

                # app.get '/api/contents/:id/?' do
                #     # {
                #     param 'id', Integer, required: true
                #     # }

                #     content = Content[ id: params['id'] ]
                #     halt( 404, 'Content inconnue' ) if content.nil? || ( !content.dtime.nil? && content.dtime < UNDELETE_TIME_WINDOW.minutes.ago )
                #     halt( 401, '401 Unauthorized' ) unless content.author_id == get_ctxt_user( user['id'] ).id

                #     json( content )
                # end

                # app.post '/api/contents/?' do
                #     # {
                #     param 'contents', Array, require: true
                #     # [{ 'timeslot_id', Integer, required: true
                #     #    'content', String }]
                #     # }

                #     author_id = get_ctxt_user( user['id'] ).id

                #     result = params['contents'].map do |content|
                #         content = JSON.parse( content ) if content.is_a?( String )

                #         timeslot = Timeslot[ id: content['timeslot_id'] ]

                #         halt( 409, 'Créneau invalide' ) if timeslot.nil?

                #         content = Content.create( author_id: author_id,
                #                             timeslot_id: timeslot.id,
                #                             date: content['date'].to_s,
                #                             ctime: Time.now,
                #                             content: content['content'] )
                #         content.save

                #         content
                #     end

                #     json( result )
                # end

                # app.put '/api/contents/:id/?' do
                #     # {
                #     param 'id', Integer, required: true
                #     param 'date', Date
                #     param 'content', String
                #     # }

                #     content = Content[ id: params['id'] ]

                #     halt( 404, 'Content inconnue' ) if content.nil?

                #     halt( 401, '401 Unauthorized' ) unless content.author_id == get_ctxt_user( user['id'] ).id

                #     content.update( date: params['date'] ) if params.key?( 'date' )
                #     content.update( content: params['content'] ) if params.key?( 'content' )
                #     content.update( mtime: Time.now )
                #     content.save

                #     json( content )
                # end

                # app.delete '/api/contents/:id/?' do
                #     # {
                #     param 'id', Integer, required: true
                #     # }

                #     content = Content[ id: params['id'] ]
                #     halt( 404, 'Content inconnu' ) if content.nil?

                #     halt( 401, '401 Unauthorized' ) unless content.author_id == get_ctxt_user( user['id'] ).id

                #     content.update( dtime: content.dtime.nil? ? Time.now : nil, mtime: Time.now )
                #     content.save

                #     json( content )
                # end
            end
        end
    end
end
