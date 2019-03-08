# frozen_string_literal: true

Sequel.migration do
    change do
        puts '041_add_table_resource_types.rb'

        create_table!(:resource_types) do
            primary_key :id

            String :label, null: false
            String :description
        end
        [%w[Salle Salle],
         %w[Matériel Matériel]].each do |resource_type|
            self[:resource_types].insert( %i[label description], resource_type )
        end

        alter_table( :resources ) do
            add_foreign_key :resource_type_id, :resource_types, null: true
        end
        DB[:resources].update(resource_type_id: DB[:resource_types].all.first[:id])

        alter_table( :resources ) do
            set_column_not_null :resource_type_id
        end
    end
end
