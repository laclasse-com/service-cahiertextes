# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :matchables ) do
            rename_column( :id_annuaire, :known_id )
        end
    end
end
puts '030_rename_id_annuaire.rb'
