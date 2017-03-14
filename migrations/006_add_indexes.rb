# coding: utf-8

Sequel.migration do
  change do
    alter_table(:etablissements) do
      add_index :id

      add_index :UAI
    end

    alter_table(:plages_horaires) do
      add_index :id
    end

    alter_table(:salles) do
      add_index :id
    end

    alter_table(:creneaux_emploi_du_temps) do
      add_index :id
    end

    alter_table(:ressources) do
      add_index :id
    end

    alter_table(:cahiers_de_textes) do
      add_index :id

      add_index :regroupement_id
    end

    alter_table(:cours) do
      add_index :id
    end

    alter_table(:types_devoir) do
      add_index :id
    end

    alter_table(:devoirs) do
      add_index :id
    end

    alter_table(:devoir_todo_items) do
      add_index :id
      add_index :eleve_id
    end
  end
end
puts 'applying 006_add_indexes.rb'
