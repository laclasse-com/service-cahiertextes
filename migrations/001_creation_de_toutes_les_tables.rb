# coding: utf-8

Sequel.migration do
  change do
    create_table!(:etablissement) {
      primary_key :id
      String :UAI
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      Date :date_premier_jour_premiere_semaine
    }

    create_table!(:plage_horaire) {
      primary_key :id
      String :label
      Time :debut, only_time: true
      Time :fin, only_time: true
    }

    create_table!(:salle) {
      primary_key :id
      foreign_key :etablissement_id, :etablissement
      String :identifiant
      String :nom
    }

    create_table!(:creneau_emploi_du_temps) {
      primary_key :id
      foreign_key :debut, :plage_horaire
      foreign_key :fin, :plage_horaire
      Integer :jour_de_la_semaine
      Integer :matiere_id, null: false # tiré de l'annuaire en fonction de (établissement, code, libellé)
    }

    create_table!(:creneau_emploi_du_temps_salle) {
      primary_key [:creneau_emploi_du_temps_id, :salle_id]
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      foreign_key :salle_id, :salle
      Bignum :semaines_de_presence, unsigned: true
    }

    create_table!(:creneau_emploi_du_temps_enseignant) {
      primary_key [:creneau_emploi_du_temps_id, :enseignant_id]
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :enseignant_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom)
      Bignum :semaines_de_presence, unsigned: true
    }

    create_table!(:creneau_emploi_du_temps_regroupement) {
      primary_key [:creneau_emploi_du_temps_id, :regroupement_id]
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :regroupement_id    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Bignum :semaines_de_presence, unsigned: true
    }

    create_table!(:ressource) {
      primary_key :id
      String :label
      Integer :doc_id  # TODO: remplacer par une URL?
    }

    create_table!(:cahier_de_textes) {
      primary_key :id
      Integer :regroupement_id    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      DateTime :date_creation
      String :label
      TrueClass :deleted, default: false
    }

    create_table!(:cours) {
      primary_key :id
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      foreign_key :cahier_de_textes_id, :cahier_de_textes
      Integer :enseignant_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom)
      Date :date_cours
      DateTime :date_creation
      DateTime :date_modification
      DateTime :date_validation
      String :contenu, size: 4096           # séquence pédagogique
      TrueClass :deleted, default: false
    }
    drop_table?(:cours_ressource)
    create_join_table(cours_id: :cours, ressource_id: :ressource)

    create_table!(:type_devoir) {
      primary_key :id
      String :label
      String :description
    }

    create_table!(:devoir) {
      primary_key :id
      foreign_key :cours_id, :cours
      foreign_key :type_devoir_id, :type_devoir
      DateTime :date_creation
      String :contenu, size: 4096
      DateTime :date_modification
      DateTime :date_validation
      Date :date_due
      Integer :temps_estime
    }
    drop_table?(:devoir_ressource)
    create_join_table(devoir_id: :devoir, ressource_id: :ressource)

    create_table!(:devoir_todo_item) {
      primary_key :id
      foreign_key :devoir_id, :devoir
      Integer :eleve_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom, sexe, date_de_naissance)
      DateTime :date_fait
    }
  end
end
