# frozen_string_literal: true

Sequel.migration do
    change do
        create_table!(:notes) do
            primary_key :id

            foreign_key :timeslot_id, :timeslots, null: false
            String :author_id, null: false
            String :content, size: 4096
            DateTime :ctime
            DateTime :mtime
            DateTime :dtime
        end

        create_table!( :notes_attachments) do
            primary_key %i[note_id attachment_id]
            foreign_key :note_id, :notes, null: false
            foreign_key :attachment_id, :attachments, null: false
        end
    end
end
puts 'applying 049_add_table_notes.rb'
