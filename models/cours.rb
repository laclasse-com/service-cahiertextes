# -*- coding: utf-8 -*-

class Cours < Sequel::Model( :cours )
  many_to_many :ressource
  many_to_one :creneau_emploi_du_temps
  many_to_one :cahier_de_textes
end

class CoursRessource < Sequel::Model( :cours_ressource )

end
