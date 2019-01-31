# frozen_string_literal: true

Sequel.migration do
    change do
        [:sessions, :assignments].each do |table|
            alter_table( table ) do
                set_column_not_null :content
            end
        end
    end
end
puts 'applying 052_content_not_nullable.rb'
