# -*- coding: utf-8 -*-

class Ressource < Sequel::Model( :ressources )
  many_to_many :cours, class: :Cours, join_table: :cours_ressources
  many_to_many :devoirs, join_table: :devoirs_ressources
end
