# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :matchables ) do
            drop_index( :hash_item, name: :sha256 )
        end
    end
end
puts 'applying 020_matchables_hash_not_unique.rb'
