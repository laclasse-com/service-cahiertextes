# frozen_string_literal: true

class Resource < Sequel::Model( :resources )
    many_to_one :structures
    many_to_many :timeslots, join_table: :reservations
    one_to_many :reservations
    many_to_one :imports
    many_to_one :author, key: :author_id
end
