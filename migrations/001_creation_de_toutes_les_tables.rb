# coding: utf-8

Sequel.migration do
  change do
    create_table!(:etablissements) do
      primary_key :id

      String :UAI, null: false
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      Date :date_premier_jour_premiere_semaine
    end

    create_table!(:plages_horaires) do
      primary_key :id

      String :label, null: false
      Time :debut, null: false, only_time: true
      Time :fin, null: false, only_time: true
    end

    create_table!(:salles) do
      primary_key :id
      foreign_key :etablissement_id, :etablissements, null: false

      String :identifiant, null: false
      String :nom
    end

    create_table!(:creneaux_emploi_du_temps) do
      primary_key :id
      foreign_key :debut, :plages_horaires, null: false
      foreign_key :fin, :plages_horaires, null: false

      Integer :jour_de_la_semaine, null: false
      String :matiere_id, null: false
      TrueClass :deleted, default: false
      DateTime :date_creation,  null: false, default: Time.now
      DateTime :date_suppression
    end

    create_table!(:creneaux_emploi_du_temps_salles) do
      primary_key [:creneau_emploi_du_temps_id, :salle_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps, null: false
      foreign_key :salle_id, :salles, null: false

      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1, null: false
    end

    create_table!(:creneaux_emploi_du_temps_enseignants) do
      primary_key [:creneau_emploi_du_temps_id, :enseignant_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps, null: false

      String :enseignant_id, null: false
      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1, null: false
    end

    create_table!(:creneaux_emploi_du_temps_regroupements) do
      primary_key [:creneau_emploi_du_temps_id, :regroupement_id]
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps, null: false

      String :regroupement_id, null: false
      Bignum :semaines_de_presence, unsigned: true, default: 2**53 - 1, null: false
    end

    create_table!(:ressources) do
      primary_key :id

      String :name, null: false
      String :hash, null: false
    end

    create_table!(:cahiers_de_textes) do
      primary_key :id

      String :regroupement_id, null: false, unique: true
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      DateTime :date_creation, null: false
      String :label
      TrueClass :deleted, default: false
    end

    create_table!(:cours) do
      primary_key :id
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps, null: false
      foreign_key :cahier_de_textes_id, :cahiers_de_textes, null: false

      String :enseignant_id, null: false
      Date :date_cours, null: false
      DateTime :date_creation, null: false
      DateTime :date_modification
      DateTime :date_validation
      String :contenu, size: 4096
      TrueClass :deleted, default: false
    end
    drop_table?(:cours_ressources)
    create_join_table(cours_id: :cours, ressource_id: :ressources)

    create_table!(:types_devoir) do
      primary_key :id

      String :label, null: false
      String :description
    end
    [ [ 'DS', 'Devoir surveillé' ],
      [ 'DM', 'Devoir à la maison' ],
      [ 'Leçon', 'Leçon à apprendre' ],
      [ 'Exposé', 'Exposé à préparer' ],
      [ 'Recherche', 'Recherche à faire' ],
      [ 'Travail', 'Travail à faire' ]
    ].each do |type_devoir|
      self[:types_devoir].insert( [ :label, :description ], type_devoir )
    end

    create_table!(:devoirs) do
      primary_key :id
      foreign_key :cours_id, :cours, null: false
      foreign_key :creneau_emploi_du_temps_id, :creneaux_emploi_du_temps, null: false
      foreign_key :type_devoir_id, :types_devoir, null: false

      String :contenu, size: 4096
      DateTime :date_creation, null: false
      DateTime :date_modification
      DateTime :date_validation
      Date :date_due, null: false
      Integer :temps_estime
    end
    drop_table?(:devoirs_ressources)
    create_join_table(devoir_id: :devoirs, ressource_id: :ressources)

    create_table!(:devoir_todo_items) do
      primary_key :id
      foreign_key :devoir_id, :devoirs, null: false

      String :eleve_id, null: false
      DateTime :date_fait, null: false
    end
  end
end
