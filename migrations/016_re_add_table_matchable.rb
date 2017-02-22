# coding: utf-8

Sequel.migration do
  change do
    create_table!(:matchable) do
      String :hash, primary_key: true
      String :id_annuaire, null: true, unique: false
    end
  end
end
