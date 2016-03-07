# coding: utf-8

Sequel.migration do
  up do
    alter_table( :salles ) do
      add_foreign_key :etablissement_id, :etablissements, null: true
    end
  end

  down do
    alter_table( :salles ) do
      drop_foreign_key :etablissement_id
    end
  end
end
