# coding: utf-8

Sequel.migration do
  change do
    alter_table :devoirs do
      set_column_allow_null :cours_id
    end
  end
end
puts 'applying 003_optional_link_devoir_cours.rb'
