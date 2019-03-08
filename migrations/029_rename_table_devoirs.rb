# frozen_string_literal: true

Sequel.migration do
    change do
        puts '029_rename_table_devoirs.rb'

        rename_table( :types_devoir, :assignment_types )

        rename_table( :devoirs, :assignments )

        alter_table( :assignments ) do
            rename_column( :type_devoir_id, :assignment_type_id )
            rename_column( :date_creation, :ctime )
            rename_column( :date_modification, :mtime )
            rename_column( :date_validation, :vtime )
            rename_column( :contenu, :content )
            rename_column( :enseignant_id, :author_id )
            rename_column( :temps_estime, :time_estimate )
        end

        rename_table( :devoirs_resources, :assignments_resources )

        alter_table( :assignments_resources ) do
            rename_column( :devoir_id, :assignment_id )
        end

        rename_table( :devoir_todo_items, :assignment_done_markers )

        alter_table( :assignment_done_markers ) do
            rename_column( :devoir_id, :assignment_id )
            rename_column( :eleve_id, :author_id )
            rename_column( :date_fait, :rtime ) # realisation time
        end
    end
end
