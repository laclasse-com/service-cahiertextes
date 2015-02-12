# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesApp::Helpers::DataExtraction do
  subject do
    Class.new { include CahierDeTextesApp::Helpers::DataExtraction }
  end

  before :each do
    TableCleaner.new( DB, [] ).clean

    [ [ 'DS', 'Devoir surveillé' ],
      [ 'DM', 'Devoir à la maison' ],
      [ 'Leçon', 'Leçon à apprendre' ],
      [ 'Exposé', 'Exposé à préparer' ],
      [ 'Recherche', 'Recherche à faire' ],
      [ 'Travail', 'Travail à faire' ]
    ].each do |type_devoir|
      TypeDevoir.create( label: type_devoir.first,
                         description: type_devoir.last )
    end

    ph = PlageHoraire.create( label: 'dummy_PH',
                              debut: Time.parse( '14:00' ),
                              fin: Time.parse( '15:00' ))

    5.times { |i|
      cedt = CreneauEmploiDuTemps.create( debut: ph.id,
                                          fin: ph.id,
                                          jour_de_la_semaine: i + 1,
                                          matiere_id: '001122',
                                          deleted: false,
                                          date_creation: Time.now,
                                          date_suppression: nil )

      CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
      cedt.add_enseignant( enseignant_id: "enseignant_#{i + 1}" )
      CreneauEmploiDuTempsEnseignant.restrict_primary_key

      CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
      cedt.add_regroupement( regroupement_id: i + 1 )
      CreneauEmploiDuTempsRegroupement.restrict_primary_key

      if (i + 1).even?
        ct = CahierDeTextes.create( date_creation: Time.now,
                                    regroupement_id: i + 1 )

        sp = Cours.create( creneau_emploi_du_temps_id: cedt.id,
                           cahier_de_textes_id: ct.id,
                           enseignant_id: "enseignant_#{i + 1}",
                           date_cours: Date.parse( '2015-01-05' ) + i.day,
                           contenu: 'Séquence pédagogique de test' )
        cedt.add_cour( sp )

        d = Devoir.create( creneau_emploi_du_temps_id: cedt.id,
                           cours_id: sp.id,
                           type_devoir_id: TypeDevoir.first.id,
                           date_due: Date.parse( '2015-01-05' ) + i.day + 1.week,
                           contenu: 'Devoir de test' )
        cedt.add_devoir( d )
      end
    }
  end

  it 'Process the EmploiDu Temps of an élève' do
    # There's no CahierDeTextes for the regroupement yet
    expect( CahierDeTextes.where( regroupement_id: 1 ).first ).to be_nil

    edt = subject.new.emploi_du_temps( Date.parse( '2015-01-05' ),
                                       Date.parse( '2015-01-05' ) + 6.days,
                                       [ 1 ],
                                       nil )

    # The CahierDeTextes has been created
    expect( CahierDeTextes.where( regroupement_id: 1 ).first ).to_not be_nil

    expect( edt ).to_not be_nil
    expect( edt.count ).to eq 1
  end

  it 'Process the EmploiDu Temps of an élève #2' do
    edt = subject.new.emploi_du_temps( Date.parse( '2015-01-05' ),
                                       Date.parse( '2015-01-05' ) + 6.days,
                                       [ 1, 3, 5 ],
                                       nil )

    expect( edt.count ).to eq 3
  end

  it 'Process the EmploiDu Temps of an élève for a month' do
    edt = subject.new.emploi_du_temps( Date.parse( '2015-01-05' ),
                                       Date.parse( '2015-01-05' ) + 6.days,
                                       [ 1, 2, 3, 4, 5 ],
                                       nil )

    expect( edt.count ).to eq 5
    expect( edt.map { |c| c[:cours] }.flatten.compact.count ).to eq 2
    expect( edt.map { |c| c[:devoirs] }.flatten.compact.count ).to eq 0
  end

  it 'Process the EmploiDu Temps of an élève for a month' do
    edt = subject.new.emploi_du_temps( Date.parse( '2015-01-05' ) + 1.week,
                                       Date.parse( '2015-01-05' ) + 1.week + 6.days,
                                       [ 1, 2, 3, 4, 5 ],
                                       nil )

    expect( edt.count ).to eq 5
    expect( edt.map { |c| c[:cours] }.flatten.compact.count ).to eq 0
    expect( edt.map { |c| c[:devoirs] }.flatten.compact.count ).to eq 2
  end
end
