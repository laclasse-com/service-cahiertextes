# frozen_string_literal: true

class Resource < Sequel::Model( :resources )
    many_to_one :structures
    many_to_many :timeslots, join_table: :timeslots_resources
end
