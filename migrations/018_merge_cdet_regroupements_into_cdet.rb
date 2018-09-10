# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :creneaux_emploi_du_temps ) do
            add_column( :regroupement_id, Integer, null: false )
            add_column( :semainier, :Bignum, unsigned: true, null: false, default: 2**52 - 1 )
        end

        DB[:creneaux_emploi_du_temps_regroupements].all.each do |cedtr|
            DB[:creneaux_emploi_du_temps].where( id: cedtr[:creneau_emploi_du_temps_id] )
                                         .update( regroupement_id: cedtr[:regroupement_id],
                                                  semainier: cedtr[:semainier] )
        end

        drop_table(:creneaux_emploi_du_temps_regroupements)
    end
end
puts 'applying 018_merge_cdet_regroupements_into_cdet.rb'
