# frozen_string_literal: true

class Import < Sequel::Model( :imports )
    many_to_one :structures
    one_to_many :timeslots
    many_to_one :import_types
end

class ImportType < Sequel::Model( :import_types )
end
