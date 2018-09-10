# frozen_string_literal: true

require 'json'

Sequel.migration do
    up do
        create_table!(:users_parameters) do
            primary_key :id

            String :uid, null: false, unique: true
            String :parameters, null: false, default: { affichage_types_de_devoir: true,
                                                        affichage_week_ends: false }.to_json
            DateTime :date_connexion,  null: false, default: Time.now
        end
    end
end
puts 'applying 005_add_user_parameters_table.rb'
