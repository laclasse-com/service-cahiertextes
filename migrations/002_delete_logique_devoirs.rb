# frozen_string_literal: true

Sequel.migration do
    change do
        puts '002_delete_logique_devoirs.rb'

        add_column :devoirs, :deleted, TrueClass, default: false
    end
end
