# frozen_string_literal: true

class Import < Sequel::Model( :imports )
    many_to_one :structures
    one_to_many :timeslots
    one_to_many :resources
    many_to_one :import_types
    many_to_one :users, key: :author_id
end

class ImportType < Sequel::Model( :import_types )
end
