# coding: utf-8

Sequel.migration do
  change do
    create_table(:cahier_de_textes) {
      primary_key :id
      Integer :regroupement_id    # tiré depuis l'annuaire en fonction de (établissement, nom)
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      DateTime :date_creation
      String :label
      TrueClass :deleted, default: false
    }
  end
end
