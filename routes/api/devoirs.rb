# coding: utf-8
module CahierDeTextesApp
  module Routes
    module Api
      module Devoirs
        def self.registered( app )
          app.get '/api/devoirs/?' do
            halt( 401, '401 Unauthorized' ) unless !params.key?('uid') || ( user['id'] == params['uid'] ||
                                                                            !user['children'].find { |child| child['child_id'] == params['uid'] }.nil? )

            return [] if (!params.key?('groups_ids') || params['groups_ids'].empty?) && (!params.key?('timeslots_ids') || params['timeslots_ids'].empty?)

            query = Devoir

            query = query.where( timeslot_id: params['timeslots_ids']) if params.key?( 'timeslots_ids' )

            query = query.where( timeslot_id: Timeslot.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

            query = query.where( cours_id: params['cours_ids']) if params.key?( 'cours_ids' )

            query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{Date.parse( params['date_due>'] )}'" ) ) if params.key?( 'date_due>' )

            query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{Date.parse( params['date_due<'] )}'" ) ) if params.key?( 'date_due<' )

            query = query.where( Sequel.~( Sequel.qualify( 'devoirs', 'deleted' ) ) ) unless params.key?( 'include_deleted')

            data = query.all.map(&:to_deep_hash)

            if params.key?('uid') && params.key?('check_done') && params['check_done'] == 'true'
              data.each do |devoir|
                dti = DevoirTodoItem[ devoir_id: devoir[:id], eleve_id: params['uid'] ]
                devoir[:date_fait] = dti.date_fait unless dti.nil?
                devoir[:fait] = !dti.nil?
              end
            end

            json( data )
          end

          app.get '/api/devoirs/:id/?' do
            devoir = Devoir[ params['id'] ]

            halt( 404, 'Devoir inconnu' ) if devoir.nil? || ( devoir.deleted && devoir.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

            hd = devoir.to_deep_hash
            if params['uid']
              dti = DevoirTodoItem[ devoir_id: devoir.id, eleve_id: user['id'] ]
              hd[:date_fait] = dti.date_fait unless dti.nil?
            end

            json( hd )
          end

          app.post '/api/devoirs/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            timeslot = Timeslot[ body['timeslot_id'] ]
            halt( 409, 'Créneau invalide' ) if timeslot.nil?

            devoir = Devoir.create( enseignant_id: user['id'],
                                    type_devoir_id: body['type_devoir_id'],
                                    timeslot_id: timeslot.id,
                                    contenu: body['contenu'],
                                    date_due: body['date_due'],
                                    temps_estime: body['temps_estime'],
                                    date_creation: Time.now )

            if body['cours_id'] && !body['cours_id'].nil?
              devoir.update( cours_id: body['cours_id'] )
            else
              cours = Cours.where( timeslot_id: timeslot.id )
                           .where( date_cours: body['date_due'] )
                           .where( deleted: false )
                           .first
              if cours.nil?
                cours = Cours.create( enseignant_id: user['id'],
                                      textbook_id: DataManagement::Accessors.create_or_get( TextBook, regroupement_id: timeslot.regroupement_id ).id,
                                      timeslot_id: timeslot.id,
                                      date_cours: body['date_due'],
                                      date_creation: Time.now,
                                      contenu: '' )
              end
              devoir.update( cours_id: cours.id )
            end

            params['enseignant_id'] = user['id']

            devoir.modifie( body )

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            devoir = Devoir[ params['id'] ]
            halt( 404, 'Devoir inconnu' ) if devoir.nil?
            params['enseignant_id'] = user['id']

            devoir.modifie( body )

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/fait/?' do
            user_needs_to_be( %w[ ELV ] )

            devoir = Devoir[ params['id'] ]

            devoir.toggle_fait( user )

            hd = devoir.to_deep_hash
            dti = DevoirTodoItem[ devoir_id: devoir.id, eleve_id: user['id'] ]
            hd[:date_fait] = dti.date_fait unless dti.nil?
            hd[:fait] = !dti.nil?

            json( hd )
          end

          app.delete '/api/devoirs/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            devoir = Devoir[ params['id'] ]

            devoir.toggle_deleted

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/copie/cours/:cours_id/timeslot/:timeslot_id/date_due/:date_due' do
            user_needs_to_be( %w[ ENS DOC ] )

            # request.body.rewind
            # body = JSON.parse( request.body.read )

            devoir = Devoir[ params['id'] ]
            halt( 404, 'Devoir inconnu' ) if devoir.nil?

            devoir.copie( params['cours_id'], params['timeslot_id'], params['date_due'] )

            json( devoir.to_deep_hash )
          end
        end
      end
    end
  end
end
