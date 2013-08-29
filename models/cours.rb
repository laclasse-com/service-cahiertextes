# -*- coding: utf-8 -*-

class Cours < Sequel::Model( :cours )
  many_to_many :ressource
  many_to_one :creneau_emploi_du_temps
  many_to_one :cahier_de_textes

  attr_accessor :enseignant_id
  attr_accessor :date_cours
  attr_accessor :date_creation
  attr_accessor :date_modification
  attr_accessor :date_validation
  attr_accessor :contenu
  attr_accessor :deleted
end

class CoursRessource < Sequel::Model( :cours_ressource )

end
