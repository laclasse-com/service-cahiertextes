# coding: utf-8
require 'spec_helper'

describe TextBook do
  before :each do
    TableCleaner.new( DB, [] ).clean

    [['DS', 'Devoir surveillé'],
     ['DM', 'Devoir à la maison'],
     ['Leçon', 'Leçon à apprendre'],
     ['Exposé', 'Exposé à préparer'],
     ['Recherche', 'Recherche à faire'],
     ['Travail', 'Travail à faire']].each do |type_devoir|
      TypeDevoir.create( label: type_devoir.first,
                         description: type_devoir.last )
    end

    etab = Structure.create( UAI: '012345Z' )

    5.times do |i|
      cedt = CreneauEmploiDuTemps.create( debut: Time.parse( '14:00' ),
                                          fin: Time.parse( '15:00' ),
                                          jour_de_la_semaine: i + 1,
                                          structure_id: etab.id,
                                          matiere_id: '001122',
                                          regroupement_id: i + 1,
                                          deleted: false,
                                          date_creation: Time.now,
                                          date_suppression: nil )

      next unless (i + 1).even?

      ct = TextBook.create( ctime: Time.now,
                            group_id: i + 1 )

      sp = Session.create( timeslot_id: cedt.id,
                         textbook_id: ct.id,
                         author_id: "enseignant_#{i + 1}",
                         date: Date.parse( "#{Time.now.year}-09-01" ) + i.day,
                         ctime: Time.now,
                         content: 'Séquence pédagogique de test' )
      cedt.add_cour( sp )

      d = Devoir.create( creneau_emploi_du_temps_id: cedt.id,
                         enseignant_id: "enseignant_#{i + 1}",
                         session_id: sp.id,
                         type_devoir_id: TypeDevoir.first.id,
                         date_due: Date.parse( "#{Time.now.year}-09-01" ) + i.day + 1.week,
                         date_creation: Time.now,
                         contenu: 'Devoir de test' )
      cedt.add_devoir( d )
    end
  end

  it 'Calcule les statistiques du cahier de textes d\'un regroupement' do
    stats = TextBook.first.statistiques

    expect( stats[:group_id] ).to eq '2'
  end
end
