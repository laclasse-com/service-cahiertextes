# frozen_string_literal: true

class Import < Sequel::Model( :imports )
    many_to_one :structures
    one_to_many :timeslots
    one_to_many :resources
    many_to_one :author, key: :author_id, class: :User
end
