# frozen_string_literal: true

Sequel.migration do
    change do
        puts '037_rename_table_locations.rb'

        rename_table( :locations, :resources )

        rename_table( :timeslots_locations, :timeslots_resources )

        alter_table( :timeslots_resources ) do
            rename_column( :location_id, :resource_id )
        end
    end
end
