Sequel.migration do
  up do
    alter_table( :creneaux_emploi_du_temps ) do
      add_foreign_key :etablissement_id, :etablissements, null: true
    end
    alter_table( :salles ) do
      drop_foreign_key :etablissement_id
    end
  end

  down do
    alter_table( :salles ) do
      add_foreign_key :etablissement_id, :etablissements, null: false
    end
    alter_table( :creneaux_emploi_du_temps ) do
      drop_foreign_key :etablissement_id
    end
  end
end
puts 'applying 008_tie_creneau_to_etablissement.rb'
