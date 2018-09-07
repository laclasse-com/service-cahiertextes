module Routes
    module Api
        module TextBooks
            def self.registered( app )
                app.post '/api/textbooks/?' do
                    # {
                    param :group_id, Integer, required: true
                    param :label, String, required: true
                    param :schoolyear_start, Date, required: true
                    param :schoolyear_end, Date, required: true
                    # }

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
                    # {
                    param :textbooks, Array, required: true
                    # }

                    user_needs_to_be( %w[ ADM DIR ] )

                    json( params['textbooks'].map do |ct|
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
