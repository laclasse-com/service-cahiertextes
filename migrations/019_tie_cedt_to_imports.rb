# coding: utf-8

Sequel.migration do
  up do
    alter_table( :creneaux_emploi_du_temps ) do
      add_foreign_key :import_id, :imports, null: true
    end
  end

  down do
    alter_table( :creneaux_emploi_du_temps ) do
      drop_foreign_key :import_id
    end
  end
end
puts 'applying 019_tie_cedt_to_imports.rb'
