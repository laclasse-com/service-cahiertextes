# frozen_string_literal: true

Sequel.migration do
    change do
        create_table!(:import_types) do
            primary_key :id

            String :label, null: false
            String :description
        end
        [['pronote', 'Import fichier EDT Index-Éducation']].each do |import_type|
            self[:import_types].insert( %i[label description], import_type )
        end

        alter_table( :imports ) do
            add_foreign_key :import_type_id, :import_types, null: true
        end
    end
end
puts 'applying 042_add_table_import_types.rb'
