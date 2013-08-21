# coding: utf-8

Sequel.migration do
  change do
    create_table(:cours) {
      primary_key :id
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      foreign_key :cahier_de_textes_id, :cahier_de_textes
      Integer :enseignant_id
      Date :date_cours
      DateTime :date_creation
      DateTime :date_modification
      DateTime :date_validation
      String :contenu
      TrueClass :deleted, default: false
    }
    create_join_table(cours_id: :cours, ressource_id: :ressource)
  end
end
