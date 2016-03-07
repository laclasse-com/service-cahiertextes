# coding: utf-8

Sequel.migration do
  up do
    alter_table( :creneaux_emploi_du_temps ) do
      set_column_allow_null( :debut )
      set_column_allow_null( :fin )
    end
  end

  down do
    alter_table( :creneaux_emploi_du_temps ) do
      set_column_not_null( :debut )
      set_column_not_null( :fin )
    end
  end
end
