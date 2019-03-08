# frozen_string_literal: true

Sequel.migration do
    change do
        puts '052_content_not_nullable.rb'

        [:sessions, :assignments].each do |table|
            alter_table( table ) do
                set_column_not_null :content
            end
        end
    end
end
