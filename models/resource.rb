class Resource < Sequel::Model( :resources )
  many_to_many :cours, class: :Cours, join_table: :cours_resources, left_key: :resource_id, right_key: :cours_id
  many_to_many :devoirs, join_table: :devoirs_resources
end
