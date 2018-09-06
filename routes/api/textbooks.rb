module CahierDeTextesApp
  module Routes
    module Api
      module TextBooks
        def self.registered( app )
          app.post '/api/textbooks/?' do
            user_needs_to_be( %w[ ADM DIR ] )

            ct = DataManagement::Accessors.create_or_get( TextBook,
                                                          group_id: params['group_id'])
            ct.update( schoolyear_start: params['schoolyear_start'],
                       schoolyear_end: params['schoolyear_end'],
                       label: params['label'] )
            ct.save

            json( ct )
          end

          app.post '/api/textbooks/bulk/?' do
            user_needs_to_be( %w[ ADM DIR ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            json( body['textbooks'].map do |ct|
                    new_ct = DataManagement::Accessors.create_or_get( TextBook,
                                                                      group_id: ct['group_id'])
                    new_ct.update( schoolyear_start: ct['schoolyear_start'],
                                   schoolyear_end: ct['schoolyear_end'],
                                   label: ct['label'] )
                    new_ct.save

                    new_ct.to_hash
                  end )
          end
        end
      end
    end
  end
end
