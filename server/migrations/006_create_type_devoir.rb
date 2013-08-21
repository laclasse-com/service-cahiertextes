# coding: utf-8

Sequel.migration do
  change do
    create_table(:type_devoir) {
      primary_key :id
      String :label
      String :description
    }
  end
end
