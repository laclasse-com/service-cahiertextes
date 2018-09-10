# frozen_string_literal: true

Sequel.migration do
    change do
        DB[:failed_identifications].delete

        rename_table :failed_identifications, :matchables

        alter_table(:matchables) do
            rename_column :sha256, :hash_item
            drop_foreign_key :import_id
            drop_column :date_creation
            add_foreign_key :etablissement_id, :etablissements, null: false
        end
    end
end
puts 'applying 014_rename_failed_identifications_into_matchables.rb'
