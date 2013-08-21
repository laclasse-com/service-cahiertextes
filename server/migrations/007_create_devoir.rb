# coding: utf-8

Sequel.migration do
  change do
    create_table(:devoir) {
      primary_key :id
      foreign_key :cours_id, :cours
      foreign_key :type_devoir_id, :type_devoir
      foreign_key :ressource_id, :ressource  # une seule ressource par cours ?
      String :contenu
      DateTime :date_creation
      DateTime :date_modification
      DateTime :date_validation
      Date :date_due
      Integer :temps_estime
    }
  end
end
