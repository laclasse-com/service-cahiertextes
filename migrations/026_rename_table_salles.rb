# frozen_string_literal: true

Sequel.migration do
    change do
        rename_table( :salles, :locations )

        alter_table( :locations ) do
            rename_column( :identifiant, :label )
            rename_column( :nom, :name )
        end

        rename_table( :timeslots_salles, :timeslots_locations )

        alter_table( :timeslots_locations ) do
            rename_column( :salle_id, :location_id )
        end
    end
end
puts "026_rename_table_salles.rb"
