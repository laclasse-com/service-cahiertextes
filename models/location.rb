class Location < Sequel::Model( :locations )
  many_to_one :structures
  many_to_many :timeslots,
               join_table: :timeslots_locations,
               left_key: :location_id,
               right_key: :timeslot_id
end
