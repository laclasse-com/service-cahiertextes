# coding: utf-8

Sequel.migration do
  change do
    create_table!(:etablissements) {
      primary_key :id
      String :UAI, null: false
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      Date :date_premier_jour_premiere_semaine
    }

    create_table!(:plages_horaires) {
      primary_key :id
      String :label, null: false
      Time :debut, null: false, only_time: true
      Time :fin, null: false, only_time: true
    }

    create_table!(:salles) {
      primary_key :id
      foreign_key :etablissement_id, :etablissements
      String :identifiant, null: false
      String :nom
    }

    create_table!(:creneaux_emploi_du_temps) {
      primary_key :id
      foreign_key :debut, :plages_horaires
      foreign_key :fin, :plages_horaires
      Integer :jour_de_la_semaine, null: false
      String :matiere_id, null: false # tiré de l'annuaire en fonction de (établissement, code, libellé)
    }

    create_table!(:creneaux_emploi_du_temps_salles) {
      primary_key [:creneau_emploi_du_temps_id, :salle_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps
      foreign_key :salle_id, :salles
      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1
    }

    create_table!(:creneaux_emploi_du_temps_enseignants) {
      primary_key [:creneau_emploi_du_temps_id, :enseignant_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps
      String :enseignant_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom)
      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1
    }

    create_table!(:creneaux_emploi_du_temps_regroupements) {
      primary_key [:creneau_emploi_du_temps_id, :regroupement_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps
      String :regroupement_id    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1
    }

    create_table!(:ressources) {
      primary_key :id
      String :label
      String :url, null: false
    }

    create_table!(:cahiers_de_textes) {
      primary_key :id
      String :regroupement_id, null: false    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      DateTime :date_creation, null: false
      String :label
      TrueClass :deleted, default: false
    }

    create_table!(:cours) {
      primary_key :id
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps
      foreign_key :cahier_de_textes_id, :cahiers_de_textes
      String :enseignant_id, null: false    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom)
      Date :date_cours, null: false
      DateTime :date_creation, null: false
      DateTime :date_modification
      DateTime :date_validation
      String :contenu, size: 4096           # séquence pédagogique
      TrueClass :deleted, default: false
    }
    drop_table?(:cours_ressources)
    create_join_table(cours_id: :cours, ressource_id: :ressources)

    create_table!(:types_devoir) {
      primary_key :id
      String :label, null: false
      String :description
    }

    create_table!(:devoirs) {
      primary_key :id
      foreign_key :cours_id, :cours
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps
      foreign_key :type_devoir_id, :types_devoir
      String :contenu, size: 4096
      DateTime :date_creation, null: false
      DateTime :date_modification
      DateTime :date_validation
      Date :date_due, null: false
      Integer :temps_estime
    }
    drop_table?(:devoirs_ressources)
    create_join_table(devoir_id: :devoirs, ressource_id: :ressources)

    create_table!(:devoir_todo_items) {
      primary_key :id
      foreign_key :devoir_id, :devoirs
      String :eleve_id, null: false    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom, sexe, date_de_naissance)
      DateTime :date_fait, null: false
    }
  end
end
