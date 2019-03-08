# frozen_string_literal: true

Sequel.migration do
    change do
        puts '036_rename_table_resources.rb'

        rename_table( :resources, :attachments )

        rename_table( :sessions_resources, :sessions_attachments )

        alter_table( :sessions_attachments ) do
            rename_column( :resource_id, :attachment_id )
        end

        rename_table( :assignments_resources, :assignments_attachments )

        alter_table( :assignments_attachments ) do
            rename_column( :resource_id, :attachment_id )
        end
    end
end
