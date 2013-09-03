# -*- coding: utf-8 -*-

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end
end

class CreneauEmploiDuTemps < Sequel::Model( :creneaux_emploi_du_temps )
  many_to_one :salle
  # FIXME: associations pour les plages horaires de début et de fin ?
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
