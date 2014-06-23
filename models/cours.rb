# -*- coding: utf-8 -*-

class Cours < Sequel::Model( :cours )
  many_to_many :ressources
  many_to_one :creneau_emploi_du_temps
  many_to_one :cahier_de_textes

  def to_hash_avec_ressources
    hash = this.to_hash
    hash[:ressources] = this.ressources.map { |rsrc| rsrc.to_hash }
    hash
  end
end

class CoursRessource < Sequel::Model( :cours_ressources )

end
