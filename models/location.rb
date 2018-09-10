# frozen_string_literal: true

class Location < Sequel::Model( :locations )
    many_to_one :structures
    many_to_many :timeslots
end
