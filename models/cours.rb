# -*- coding: utf-8 -*-

class Cours < Sequel::Model( :cours )
  many_to_many :ressources
  many_to_one :creneau_emploi_du_temps
  many_to_one :cahier_de_textes

  def to_deep_hash
    h = self.to_hash
    self.class.associations.each { |association|
      h[association] = self[association]
    }

    h
  end
end

class CoursRessource < Sequel::Model( :cours_ressources )

end
