# -*- coding: utf-8 -*-

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end
end

class CreneauEmploiDuTempsSalle < Sequel::Model( :creneaux_emploi_du_temps_salles )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
  many_to_one :salle
end

class CreneauEmploiDuTempsEnseignant < Sequel::Model( :creneaux_emploi_du_temps_enseignants )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
end

class CreneauEmploiDuTempsRegroupement < Sequel::Model( :creneaux_emploi_du_temps_regroupements )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
end

class CreneauEmploiDuTemps < Sequel::Model( :creneaux_emploi_du_temps )
  one_to_many :regroupements, class: :CreneauEmploiDuTempsRegroupement
  one_to_many :enseignants, class: :CreneauEmploiDuTempsEnseignant
  many_to_many :salles, class: :Salle, join_table: :creneaux_emploi_du_temps_salles

  one_to_many :cours, class: :Cours
  one_to_many :devoirs

  many_to_one :plage_horaire_debut, class: :PlageHoraire, key: :debut
  many_to_one :plage_horaire_fin, class: :PlageHoraire, key: :fin
end
