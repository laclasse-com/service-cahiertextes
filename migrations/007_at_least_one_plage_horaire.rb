Sequel.migration do
  change do
    self[:plages_horaires].insert( %i[label
                                      debut
                                      fin],
                                   ['default',
                                    Time.parse( '0:00' ),
                                    Time.parse( '1:00' )] )
  end
end
puts 'applying 007_at_least_one_plage_horaire.rb'
