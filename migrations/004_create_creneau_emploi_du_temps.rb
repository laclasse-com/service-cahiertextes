# coding: utf-8

require_relative '../lib/database_types.rb'

Sequel.migration do
  change do
    create_table(:creneau_emploi_du_temps) {
      primary_key :id
      Integer :jour_de_la_semaine
      foreign_key :debut, :plage_horaire
      foreign_key :fin, :plage_horaire
      Integer :matiere_id, null: false # tiré de l'annuaire en fonction de (établissement, code, libellé)
    }

    create_table(:creneau_emploi_du_temps_salle) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      foreign_key :salle_id, :salle
      Bignum :semaines_de_presence, unsigned: true
      primary_key [:creneau_emploi_du_temps_id, :salle_id]
    }

    create_table(:creneau_emploi_du_temps_enseignant) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :enseignant_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom)
      Bignum :semaines_de_presence, unsigned: true
      primary_key [:creneau_emploi_du_temps_id, :enseignant_id]
    }

    create_table(:creneau_emploi_du_temps_regroupement) {
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :regroupement_id    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Bignum :semaines_de_presence, unsigned: true
      primary_key [:creneau_emploi_du_temps_id, :regroupement_id]
    }
  end
end
