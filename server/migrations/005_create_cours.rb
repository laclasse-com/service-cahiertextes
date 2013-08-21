# coding: utf-8

Sequel.migration do
  change do
    create_table(:cours) {
      primary_key :id
      foreign_key :creneau_emploi_du_temps_id, :creneau_emploi_du_temps
      Integer :user_id  # enseignant
      Date :date_cours
      DateTime :date_creation
      DateTime :date_modification
      DateTime :date_validation
      String :description
      foreign_key :ressource_id, :ressource  # une seule ressource par cours ?
      TrueClass :deleted, default: false
    }
  end
end
