# coding: utf-8
module CahierDeTextesApp
  module Routes
    module Status
      def self.registered( app )
        app.get '/status/?' do
          content_type :json

          status = 'OK'
          reason = 'L\'application Cahier de Textes fonctionne.'

          # test DB
          if DB.nil?
            status = 'KO'
            reason = 'Base de données inaccessible.'
          end
          if DB.tables.empty?
            status = 'KO'
            reason = 'Base de données vide.'
          end

          app_status = { app_id: ANNUAIRE[:app_id],
                         app_version: APP_VERSION.nil? ? 'missing APP_VERSION' : APP_VERSION,
                         rack_env: ENV['RACK_ENV'] }

          app_status[:status] = status
          app_status[:reason] = reason

          json( app_status )
        end

        app.get '/status/report/?' do
          content_type :json

          if params.key?('from') && params.key?('to')
            json(
              nb_structures: Structure.count,
              nb_textbooks: TextBook.count,
              nb_sessions: Session
                .where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{Date.parse( params['from'] )}'" ) )
                .where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{Date.parse( params['to'] )}'" ) )
                .count,
              nb_devoirs: Devoir
                .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{Date.parse( params['from'] )}'" ) )
                .where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{Date.parse( params['to'] )}'" ) )
                .count,
              nb_devoirs_faits: DevoirTodoItem
                .where( Sequel.lit( "DATE_FORMAT( date_fait, '%Y-%m-%d') >= '#{Date.parse( params['from'] )}'" ) )
                .where( Sequel.lit( "DATE_FORMAT( date_fait, '%Y-%m-%d') <= '#{Date.parse( params['to'] )}'" ) )
                .count,
              # nb_resources: Resource.count,
              nb_timeslots: Timeslot.count
            )
          else
            json( nb_structures: Structure.count,
                  nb_textbooks: TextBook.count,
                  nb_sessions: Session.count,
                  nb_devoirs: Devoir.count,
                  nb_devoirs_faits: DevoirTodoItem.count,
                  nb_resources: Resource.count,
                  nb_timeslots: Timeslot.count )
          end
        end
      end
    end
  end
end
