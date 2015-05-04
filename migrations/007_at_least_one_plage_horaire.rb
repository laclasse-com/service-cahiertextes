# coding: utf-8

Sequel.migration do
  change do
    self[:plages_horaires].insert( [ :label,
                                     :debut,
                                     :fin ],
                                   [ 'default',
                                     Time.parse( '0:00' ),
                                     Time.parse( '1:00' ) ] )
  end
end
