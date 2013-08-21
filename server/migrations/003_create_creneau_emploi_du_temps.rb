# coding: utf-8

Sequel.migration do
  change do
    create_table(:creneau_emploi_du_temps) {
      primary_key :id
      Integer :jour_de_la_semaine
      foreign_key :debut, :plage_horaire
      foreign_key :fin, :plage_horaire
      Integer :matiere_id, null: false
    }

    create_table(:creneau_emploi_du_temps_salle) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      foreign_key :salle_id, :salle
      Integer :semaines_de_presence
      unrestricted_primary_key [:creneau_emploi_du_temps_id, :salle_id]
    }

    create_table(:creneau_emploi_du_temps_enseignant) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :enseignant_id
      Integer :semaines_de_presence
      unrestricted_primary_key [:creneau_emploi_du_temps_id, :enseignant_id]
    }

    create_table(:creneau_emploi_du_temps_regroupement) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :regroupement_id
      Integer :semaines_de_presence
      unrestricted_primary_key [:creneau_emploi_du_temps_id, :regroupement_id]
    }
  end
end
