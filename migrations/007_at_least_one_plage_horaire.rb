# frozen_string_literal: true

Sequel.migration do
    change do
        puts '007_at_least_one_plage_horaire.rb'

        self[:plages_horaires].insert( %i[label
                                          debut
                                          fin],
                                       ['default',
                                        Time.parse( '0:00' ),
                                        Time.parse( '1:00' )] )
    end
end
