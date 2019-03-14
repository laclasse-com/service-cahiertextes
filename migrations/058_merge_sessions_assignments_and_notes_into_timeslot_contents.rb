# frozen_string_literal: true

Sequel.migration do
    change do
        puts '058_merge_sessions_assignments_and_notes_into_timeslot_contents.rb'

        create_table!(:timeslot_content_types) do
            primary_key :id

            String :label, null: false
        end
        %w[session assignment note].each do |timeslot_content_type|
            DB[:timeslot_content_types].insert( %i[label], [ timeslot_content_type ] )
        end

        session_type_id = DB[:timeslot_content_types].where( label: 'session' ).first[:id]

        rename_table :sessions, :timeslot_contents
        alter_table( :timeslot_contents ) do
            add_foreign_key :timeslot_content_id, :timeslot_contents, null: true
            add_foreign_key :assignment_type_id, :assignment_types, null: true
            add_foreign_key :timeslot_content_type_id, :timeslot_content_types, null: false, default: session_type_id
            add_column :load, Integer
        end
        alter_table( :timeslot_contents ) do
            set_column_default :timeslot_content_type_id, nil
        end

        rename_table :sessions_users, :timeslot_contents_users
        alter_table( :timeslot_contents_users) do
            drop_foreign_key [:session_id]
            rename_column :session_id, :timeslot_content_id
            add_foreign_key [:timeslot_content_id], :timeslot_contents
        end

        rename_table :sessions_attachments, :timeslot_contents_attachments
        alter_table( :timeslot_contents_attachments ) do
            drop_foreign_key [:session_id]
            rename_column :session_id, :timeslot_content_id
            add_foreign_key [:timeslot_content_id], :timeslot_contents
        end

        alter_table( :assignment_done_markers ) do
            drop_foreign_key [:assignment_id]
            rename_column :assignment_id, :timeslot_content_id
            add_foreign_key [:timeslot_content_id], :timeslot_contents
        end

        note_type_id = DB[:timeslot_content_types].where( label: 'note' ).first[:id]
        DB[:notes].all.each do |note|
            new_note_id = DB[:timeslot_contents].insert( %i[timeslot_id date ctime mtime dtime content author_id timeslot_content_type_id],
                                                         [ note[:timeslot_id],
                                                           note[:date],
                                                           note[:ctime],
                                                           note[:mtime],
                                                           note[:dtime],
                                                           note[:content],
                                                           note[:author_id],
                                                           note_type_id ] )
            DB[:notes_attachments].where( note_id: note[:id] ).all.each do |attachment|
                DB[:timeslot_contents_attachments].insert( %i[timeslot_content_id attachment_id],
                                                           [ new_note_id, attachment[:attachment_id] ] )
            end
        end
        drop_table :notes_attachments
        drop_table :notes

        assignment_type_id = DB[:timeslot_content_types].where( label: 'assignment' ).first[:id]
        DB[:assignments].all.each do |assignment|
            new_assignment_id = DB[:timeslot_contents].insert( %i[timeslot_id date ctime mtime vtime atime dtime content author_id timeslot_content_id assignment_type_id trail_id load timeslot_content_type_id],
                                                               [ assignment[:timeslot_id],
                                                                 assignment[:date],
                                                                 assignment[:ctime],
                                                                 assignment[:mtime],
                                                                 assignment[:vtime],
                                                                 assignment[:atime],
                                                                 assignment[:dtime],
                                                                 assignment[:content],
                                                                 assignment[:author_id],
                                                                 assignment[:timeslot_content_id],
                                                                 assignment[:assignment_type_id],
                                                                 assignment[:trail_id],
                                                                 assignment[:load],
                                                                 assignment_type_id ] )
            DB[:assignments_attachments].where( assignment_id: assignment[:id] ).all.each do |attachment|
                DB[:timeslot_contents_attachments].insert( %i[timeslot_content_id attachment_id],
                                                           [ new_assignment_id, attachment[:attachment_id] ] )
            end
            DB[:assignments_users].where( assignment_id: assignment[:id] ).all.each do |user|
                DB[:timeslot_contents_users].insert( %i[timeslot_content_id user_id],
                                                     [ new_assignment_id, user[:user_id] ] )
            end
        end
        drop_table :assignments_attachments
        drop_table :assignments_users
        drop_table :assignments
    end
end
