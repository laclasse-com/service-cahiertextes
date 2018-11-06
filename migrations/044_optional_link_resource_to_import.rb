# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :resources ) do
            add_foreign_key :import_id, :imports, null: true
        end
    end
end
puts 'applying 044_optional_link_resource_to_import.rb'
