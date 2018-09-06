class Salle < Sequel::Model( :salles )
  many_to_one :structures
  many_to_many :timeslots,
               join_table: :timeslots_salles,
               left_key: :salle_id,
               right_key: :timeslot_id
end
