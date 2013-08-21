# coding: utf-8

Sequel.migration do
  change do
    create_table(:creneau_emploi_du_temps) {
      primary_key :id
      Integer :jour_de_la_semaine
      foreign_key :debut, :plage_horaire
      foreign_key :fin, :plage_horaire
      Integer :matiere_id, null: false
      Integer :enseignant
      Integer :regroupement
      foreign_key :salle_id, :salle
    }
  end
end
