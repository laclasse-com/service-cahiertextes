# coding: utf-8

Sequel.migration do
  change do
    rename_table :failed_identifications, :matchable

    alter_table(:matchable) do
      rename_column :sha256, :hash
      drop_foreign_key :import_id
      drop_constraint :id, type: :primary_key
      drop_column :id
      add_constraint :hash, type: :primary_key
      drop_column :date_creation
    end
  end
end
