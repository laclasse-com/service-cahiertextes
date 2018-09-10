# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :sessions ) do
            drop_foreign_key :textbook_id
        end

        drop_table :textbooks
    end
end
puts "033_drop_table_textbooks.rb"
