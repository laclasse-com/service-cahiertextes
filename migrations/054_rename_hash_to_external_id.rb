# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :attachments ) do
            rename_column :hash, :external_id
        end
    end
end
puts 'applying 054_rename_hash_to_external_id.rb'
