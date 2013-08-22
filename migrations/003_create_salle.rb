# coding: utf-8

Sequel.migration do
  change do
    create_table(:salle) {
      primary_key :id
      foreign_key :etablissement_id, :etablissement
      String :identifiant
      String :nom
    }
  end
end
