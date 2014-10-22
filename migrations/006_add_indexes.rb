# coding: utf-8

Sequel.migration do
  change do
    alter_table(:etablissements) {
      add_index :id

      add_index :UAI
    }

    alter_table(:plages_horaires) {
      add_index :id
    }

    alter_table(:salles) {
      add_index :id
    }

    alter_table(:creneaux_emploi_du_temps) {
      add_index :id
    }

    alter_table(:ressources) {
      add_index :id
    }

    alter_table(:cahiers_de_textes) {
      add_index :id

      add_index :regroupement_id
    }

    alter_table(:cours) {
      add_index :id
    }

    alter_table(:types_devoir) {
      add_index :id
    }

    alter_table(:devoirs) {
      add_index :id
    }

    alter_table(:devoir_todo_items) {
      add_index :id
      add_index :eleve_id
    }
  end
end
