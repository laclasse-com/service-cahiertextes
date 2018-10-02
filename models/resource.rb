# frozen_string_literal: true

class Resource < Sequel::Model( :resources )
    many_to_one :structures
    many_to_many :timeslots, join_table: :timeslots_resources
    many_to_one :resource_type
end

class ResourceType < Sequel::Model( :resource_types )
    one_to_many :resources
end
