#coding: utf-8
#
# include file to access all models
# generated 2012-12-12 15:12:21 +0100 by sequel_model_generator.rb
#
require 'sequel'
require_relative '../config/db'
# MODELS
require_relative 'Ressource'
require_relative 'cours'
require_relative 'cahier_textes'
require_relative 'devoir'
require_relative 'fait'
require_relative 'log_visu'
require_relative 'plage_horaire'
require_relative 'type_devoir'

#On fait manuellement l'association table=>model car elle est impossible a faire automatiquement
#(pas de lien 1<=>1 entre dataset et model stackoverflow 9408785)
MODEL_MAP = {}
DB.tables.each do |table|
  capitalize_name = table.to_s.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  begin
    MODEL_MAP[table] = Kernel.const_get(capitalize_name)
  rescue => e
    puts e.message
  end
end