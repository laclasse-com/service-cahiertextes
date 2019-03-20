# frozen_string_literal: true

class Reservation < Sequel::Model( :reservations )
    many_to_one :timeslots
    many_to_one :resources
end
