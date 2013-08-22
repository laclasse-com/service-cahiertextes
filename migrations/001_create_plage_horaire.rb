# coding: utf-8

Sequel.migration do
  change do
    create_table(:plage_horaire) {
      primary_key :id
      String :label
      Time :debut, only_time: true
      Time :fin, only_time: true
    }
  end
end
