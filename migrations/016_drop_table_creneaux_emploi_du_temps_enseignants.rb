Sequel.migration do
  change do
    drop_table( :creneaux_emploi_du_temps_enseignants )
  end
end
