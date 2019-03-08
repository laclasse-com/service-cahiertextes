# frozen_string_literal: true

Sequel.migration do
    change do
        puts '027_rename_table_ressources.rb'

        rename_table( :ressources, :resources )

        rename_table( :cours_ressources, :cours_resources )

        alter_table( :cours_resources ) do
            rename_column( :ressource_id, :resource_id )
        end

        rename_table( :devoirs_ressources, :devoirs_resources )

        alter_table( :devoirs_resources ) do
            rename_column( :ressource_id, :resource_id )
        end
    end
end
