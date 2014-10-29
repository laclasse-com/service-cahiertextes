# -*- coding: utf-8 -*-

class Ressource < Sequel::Model( :ressources )
  one_to_many :cours, class: Cours
  one_to_many :devoirs
end
