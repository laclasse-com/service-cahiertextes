class Import < Sequel::Model( :imports )
  many_to_one :structures
  one_to_many :timeslots
end
