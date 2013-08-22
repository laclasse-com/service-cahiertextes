# coding: utf-8

Sequel.migration do
  change do
    create_table(:etablissement) {
      primary_key :id
      String :UAI
      Date :debut_annee_scolaire
      Date :fin_annee_scolaire
      Date :date_premier_jour_premiere_semaine
    }
  end
end
