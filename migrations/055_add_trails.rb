# frozen_string_literal: true

Sequel.migration do
    change do
        create_table!(:trails) do
            primary_key :id

            String :label, null: false
        end
        [["Parcours avenir"],
         ["Parcours d'éducation artistique et culturelle"],
         ["Parcours santé"],
         ["Parcours citoyen"]].each do |trail|
            self[:trails].insert( %i[label], trail )
        end

        alter_table( :sessions ) do
            add_foreign_key :trail_id, :trails, null: true
        end
    end
end
puts 'applying 055_add_trails.rb'
