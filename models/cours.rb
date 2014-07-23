# -*- coding: utf-8 -*-

require_relative './ToDeepHashMixin'

class Cours < Sequel::Model( :cours )
  include ToDeepHashMixin

  many_to_many :ressources
  many_to_one :creneau_emploi_du_temps
  many_to_one :cahier_de_textes
  one_to_many :devoirs
end

class CoursRessource < Sequel::Model( :cours_ressources )

end
