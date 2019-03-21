# frozen_string_literal: true

class Reservation < Sequel::Model( :reservations )
    many_to_one :timeslot
    many_to_one :resource
end
