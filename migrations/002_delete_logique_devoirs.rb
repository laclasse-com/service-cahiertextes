# frozen_string_literal: true

Sequel.migration do
    change do
        add_column :devoirs, :deleted, TrueClass, default: false
    end
end
puts 'applying 002_delete_logique_devoirs.rb'
