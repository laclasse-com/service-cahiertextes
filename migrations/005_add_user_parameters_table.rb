# coding: utf-8

Sequel.migration do
  up do
    create_table!(:users_parameters) {
      primary_key :id

      String :uid, null: false, unique: true
      String :parameters, null: false, default: { affichage_types_de_devoir: true,
                                                  affichage_week_ends: false }.to_json
    }
  end
end
