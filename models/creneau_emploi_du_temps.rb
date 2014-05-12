# -*- coding: utf-8 -*-

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end

  def present_pour_la_semaine!( n )
    semaines_de_presence[n] = 1
  end
end

class CreneauEmploiDuTempsSalle < Sequel::Model( :creneaux_emploi_du_temps_salles )
  include SemainesDePresenceMixin
end

class CreneauEmploiDuTempsEnseignant < Sequel::Model( :creneaux_emploi_du_temps_enseignants )
  include SemainesDePresenceMixin
end

class CreneauEmploiDuTempsRegroupement < Sequel::Model( :creneaux_emploi_du_temps_regroupements )
  include SemainesDePresenceMixin
end

class CreneauEmploiDuTemps < Sequel::Model( :creneaux_emploi_du_temps )
  one_to_many :regroupements, class: :CreneauEmploiDuTempsRegroupement
  one_to_many :enseignants, class: :CreneauEmploiDuTempsEnseignant
  one_to_many :salles, class: :CreneauEmploiDuTempsSalle
end
