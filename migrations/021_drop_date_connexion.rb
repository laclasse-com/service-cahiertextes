# frozen_string_literal: true

Sequel.migration do
    up do
        alter_table( :users_parameters ) do
            drop_column :date_connexion
        end
    end
end
puts 'applying 021_drop_date_connexion.rb'
