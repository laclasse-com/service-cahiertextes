class Salle < Sequel::Model( :salles )
  many_to_one :structures
  many_to_many :creneaux_emploi_du_temps,
               class: :CreneauEmploiDuTemps,
               join_table: :creneaux_emploi_du_temps_salles,
               left_key: :salle_id,
               right_key: :creneau_emploi_du_temps_id
end
