Sequel.migration do
  change do
    # 1. add column to creneaux
    alter_table(:creneaux_emploi_du_temps) do
      add_column :tdebut, Time, null: true, only_time: true
      add_column :tfin, Time, null: true, only_time: true
    end

    # 2. copy times from PH to creneaux
    from(:creneaux_emploi_du_temps).join(:plages_horaires, id: :debut).update(tdebut: :plages_horaires__debut)
    from(:creneaux_emploi_du_temps).join(:plages_horaires, id: :fin).update(tfin: :plages_horaires__fin)

    # 3. set columns null: false
    alter_table(:creneaux_emploi_du_temps) do
      set_column_not_null( :tdebut )
      set_column_not_null( :tfin )

      drop_foreign_key( :debut )
      drop_foreign_key( :fin )

      rename_column( :tdebut, :debut )
      rename_column( :tfin, :fin )
    end

    drop_table( :plages_horaires )
  end
end
puts 'applying 013_merge_plages_horaires_into_creneaux.rb'
