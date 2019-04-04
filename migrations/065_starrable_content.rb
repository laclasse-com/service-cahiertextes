# frozen_string_literal: true

Sequel.migration do
    change do
        puts '065_starrable_content.rb'

        alter_table( :contents ) do
            add_column :starred, :boolean, default: false, null: false
        end
    end
end
