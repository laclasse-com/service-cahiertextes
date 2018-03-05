class Ressource < Sequel::Model( :ressources )
  many_to_many :cours, class: :Cours, join_table: :cours_ressources, left_key: :ressource_id, right_key: :cours_id
  many_to_many :devoirs, join_table: :devoirs_ressources
end
