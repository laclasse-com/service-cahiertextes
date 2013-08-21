# coding: utf-8

Sequel.migration do
  change do
    create_table(:cours) {
      primary_key :id
      String :jour
      foreign_key :debut, :tranche_horaire
      foreign_key :fin, :tranche_horaire
      Integer :matiere_id, null: false
      Integer :enseignant
      Integer :classe
      Integer :partie_de_classe
      Integer :groupe
      foreign_key :salle_id, :salle
    }
  end
end
