# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesApp::Helpers::DataExtraction do
  subject do
    Class.new { include CahierDeTextesApp::Helpers::DataExtraction }
  end

  before :each do
    TableCleaner.new( DB, [] ).clean
  end

  it 'Process the EmploiDu Temps of an élève' do
    ph = PlageHoraire.create( label: 'dummy_PH',
                              debut: Time.parse( '14:00' ),
                              fin: Time.parse( '15:00' ))

    cedt = CreneauEmploiDuTemps.create( debut: ph.id,
                                        fin: ph.id,
                                        jour_de_la_semaine: 1,
                                        matiere_id: '001122',
                                        deleted: false,
                                        date_creation: Time.now,
                                        date_suppression: nil )

    CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
    cedt.add_enseignant( enseignant_id: 'test_user' )
    CreneauEmploiDuTempsEnseignant.restrict_primary_key

    CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
    cedt.add_regroupement( regroupement_id: 1 )
    CreneauEmploiDuTempsRegroupement.restrict_primary_key

    # There's no CahierDeTextes for the regroupement yet
    expect( CahierDeTextes.where( regroupement_id: 1 ).first ).to be_nil
    expect( subject.new.emploi_du_temps( Date.parse( '2015-01-01' ),
                                         Date.parse( '2015-02-01' ),
                                         [ 1, 2, 3 ],
                                         nil ) ).to_not be_nil
    # The CahierDeTextes has been created
    expect( CahierDeTextes.where( regroupement_id: 1 ).first ).to_not be_nil
  end
end
