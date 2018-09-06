class Import < Sequel::Model( :imports )
  many_to_one :structures
  one_to_many :creneaux_emploi_du_temps, class: :CreneauEmploiDuTemps
end
