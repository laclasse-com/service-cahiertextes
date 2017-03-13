# coding: utf-8

Sequel.migration do
  change do
    alter_table( :devoirs ) do
      add_column :enseignant_id, String, null: false
    end

    DB[:devoirs].all.each do |devoir|
      DB[:devoirs].where(id: devoir[:id])
                  .update( enseignant_id: DB[:cours].select(:enseignant_id)
                                                    .where(id: devoir[:cours_id])
                                                    .first[:enseignant_id] )
    end

    alter_table( :devoirs ) do
      set_column_not_null :enseignant_id
    end
  end
end
