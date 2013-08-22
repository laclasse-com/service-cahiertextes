# coding: utf-8

Sequel.migration do
  change do
    create_table(:devoir_todo_item) {
      primary_key :id
      foreign_key :devoir_id, :devoir
      Integer :eleve_id    # tiré depuis l'annuaire en fonction de (etablissement, nom, prénom, sexe, date_de_naissance)
      DateTime :date_fait
    }
  end
end
