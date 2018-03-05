# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextes do
  before :each do
    TableCleaner.new( DB, [] ).clean

    [ [ 'DS', 'Devoir surveillé' ],
      [ 'DM', 'Devoir à la maison' ],
      [ 'Leçon', 'Leçon à apprendre' ],
      [ 'Exposé', 'Exposé à préparer' ],
      [ 'Recherche', 'Recherche à faire' ],
      [ 'Travail', 'Travail à faire' ] ].each do |type_devoir|
      TypeDevoir.create( label: type_devoir.first,
                         description: type_devoir.last )
    end

    etab = Etablissement.create( UAI: '012345Z' )

    5.times do |i|
      cedt = CreneauEmploiDuTemps.create( debut: Time.parse( '14:00' ),
                                          fin: Time.parse( '15:00' ),
                                          jour_de_la_semaine: i + 1,
                                          etablissement_id: etab.id,
                                          matiere_id: '001122',
                                          regroupement_id: i + 1,
                                          deleted: false,
                                          date_creation: Time.now,
                                          date_suppression: nil )

      next unless (i + 1).even?

      ct = CahierDeTextes.create( date_creation: Time.now,
                                  regroupement_id: i + 1 )

      sp = Cours.create( creneau_emploi_du_temps_id: cedt.id,
                         cahier_de_textes_id: ct.id,
                         enseignant_id: "enseignant_#{i + 1}",
                         date_cours: Date.parse( "#{Time.now.year}-09-01" ) + i.day,
                         date_creation: Time.now,
                         contenu: 'Séquence pédagogique de test' )
      cedt.add_cour( sp )

      d = Devoir.create( creneau_emploi_du_temps_id: cedt.id,
                         enseignant_id: "enseignant_#{i + 1}",
                         cours_id: sp.id,
                         type_devoir_id: TypeDevoir.first.id,
                         date_due: Date.parse( "#{Time.now.year}-09-01" ) + i.day + 1.week,
                         date_creation: Time.now,
                         contenu: 'Devoir de test' )
      cedt.add_devoir( d )
    end
  end

  it 'Calcule les statistiques du cahier de textes d\'un regroupement' do
    stats = CahierDeTextes.first.statistiques

    expect( stats[:regroupement_id] ).to eq '2'
  end
end
