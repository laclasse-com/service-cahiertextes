# frozen_string_literal: true

Sequel.migration do
    change do
        rename_table( :cours, :sessions )

        alter_table( :sessions ) do
            rename_column( :enseignant_id, :author_id )
            rename_column( :contenu, :content )
            rename_column( :date_cours, :date )
            rename_column( :date_creation, :ctime )
            rename_column( :date_modification, :mtime )
            rename_column( :date_validation, :vtime )
        end

        rename_table( :cours_resources, :sessions_resources )

        alter_table( :sessions_resources ) do
            rename_column( :cours_id, :session_id )
        end

        alter_table( :devoirs ) do
            rename_column( :cours_id, :session_id )
        end
    end
end
puts "028_rename_table_cours.rb"
