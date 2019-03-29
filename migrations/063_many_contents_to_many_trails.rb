# frozen_string_literal: true

Sequel.migration do
    change do
        puts '063_many_contents_to_many_trails.rb'

        create_table!(:contents_trails) do
            primary_key [:content_id, :trail_id]

            foreign_key :content_id, :contents
            foreign_key :trail_id, :trails
        end

        alter_table( :contents ) do
            drop_foreign_key :trail_id
        end
    end
end
