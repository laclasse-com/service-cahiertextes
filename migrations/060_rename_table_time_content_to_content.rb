# frozen_string_literal: true

Sequel.migration do
    change do
        puts '060_rename_table_time_content_to_content.rb'

        rename_table :timeslot_contents, :contents
        alter_table(:contents) do
            drop_foreign_key [:timeslot_content_id]
            rename_column :timeslot_content_id, :parent_content_id
            add_foreign_key [:parent_content_id], :contents
        end

        rename_table :timeslot_contents_users, :contents_users
        alter_table( :contents_users) do
            drop_foreign_key [:timeslot_content_id]
            rename_column :timeslot_content_id, :content_id
            add_foreign_key [:content_id], :contents
        end

        rename_table :timeslot_contents_attachments, :contents_attachments
        alter_table( :contents_attachments ) do
            drop_foreign_key [:timeslot_content_id]
            rename_column :timeslot_content_id, :content_id
            add_foreign_key [:content_id], :contents
        end

        #rename_table :timeslot_contents_done_markers, :assignment_done_markers
        alter_table( :assignment_done_markers ) do
            drop_foreign_key [:timeslot_content_id]
            rename_column :timeslot_content_id, :content_id
            add_foreign_key [:content_id], :contents
        end

    end
end
