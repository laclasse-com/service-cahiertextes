#coding: utf-8
#
# include file to access all models
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# MODELS
puts "Loading 'cahier_textes' model..."
require_relative 'cahier_textes'
puts "Loading 'cours' model..."
require_relative 'cours'
puts "Loading 'devoir' model..."
require_relative 'devoir'
puts "Loading 'fait' model..."
require_relative 'fait'
puts "Loading 'log_visu' model..."
require_relative 'log_visu'
puts "Loading 'plage_horaire' model..."
require_relative 'plage_horaire'
puts "Loading 'ressource' model..."
require_relative 'ressource'
puts "Loading 'type_devoir' model..."
require_relative 'type_devoir'

#On fait manuellement l'association table=>model car elle est impossible a faire automatiquement
#(pas de lien 1<=>1 entre dataset et model stackoverflow 9408785)
MODEL_MAP = {}
DB.tables.each do |table|
  capitalize_name = table.to_s.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  MODEL_MAP[table] = Kernel.const_get(capitalize_name) 
end
  
