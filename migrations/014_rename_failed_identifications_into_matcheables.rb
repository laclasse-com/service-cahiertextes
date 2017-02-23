# coding: utf-8

Sequel.migration do
  change do
    rename_table :failed_identifications, :matchables

    alter_table(:matchables) do
      rename_column :sha256, :hash
      drop_foreign_key :import_id
      drop_column :date_creation
    end
  end
end
