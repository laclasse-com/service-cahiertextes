Sequel.migration do
  change do
    create_table!(:failed_identifications) do
      primary_key :id

      Date :date_creation, null: false, default: Time.now
      String :sha256, null: false, unique: true
      String :id_annuaire, null: true, unique: false
    end
  end
end
puts 'applying 004_add_import_correction_table.rb'
