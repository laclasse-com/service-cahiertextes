# coding: utf-8

Sequel.migration do
  up do
    create_table!(:imports) do
      primary_key :id

      foreign_key :etablissement_id, :etablissements, null: false

      Date :date_import
      String :type
      Integer :stage
    end

    alter_table( :failed_identifications ) do
      add_foreign_key :import_id, :imports, null: true
    end
  end

  down do
    alter_table( :failed_identifications ) do
      drop_foreign_key :import_id
    end

    drop_table!( :imports )
  end
end
puts 'applying 009_add_table_import.rb'
