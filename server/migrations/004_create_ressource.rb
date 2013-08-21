# coding: utf-8

Sequel.migration do
  change do
    create_table(:ressource) {
      primary_key :id
      String :label
      Integer :doc_id  # TODO: remplacer par une URL?
    }
  end
end
