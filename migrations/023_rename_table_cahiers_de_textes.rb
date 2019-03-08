# frozen_string_literal: true

Sequel.migration do
    change do
        puts '023_rename_table_cahiers_de_textes.rb'

        rename_table( :cahiers_de_textes, :textbooks )

        alter_table( :textbooks ) do
            rename_column( :debut_annee_scolaire, :schoolyear_start )
            rename_column( :fin_annee_scolaire, :schoolyear_end )
            rename_column( :regroupement_id, :group_id )
            rename_column( :date_creation, :ctime )
        end

        alter_table( :cours ) do
            rename_column( :cahier_de_textes_id, :textbook_id )
        end
    end
end
