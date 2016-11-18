#-*- coding: utf-8 -*-

require 'spec_helper'

describe CreneauEmploiDuTemps do
  before :each do
    @etablissement = Etablissement.create( UAI: 'test012345Z' )
    @jour_de_la_semaine = rand( 1..5 )
    @creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                            debut: Time.parse( '14:00' ),
                                            fin: Time.parse( '15:00' ),
                                            jour_de_la_semaine: @jour_de_la_semaine,
                                            matiere_id: '',
                                            etablissement_id: @etablissement.id )
    @salle = Salle.create( etablissement_id: @etablissement.id,
                           identifiant: 'test' )
  end
  after :each do
    @creneau.enseignants.map( &:destroy )
    @creneau.regroupements.map( &:destroy )
    @creneau.remove_all_salles
    @creneau.destroy
    @salle.destroy
    @etablissement.destroy
  end

  it 'creates a placeholder creneau' do
    expect( @creneau ).to_not be_nil
    expect( @creneau.regroupements ).to be_empty
    expect( @creneau.enseignants ).to be_empty
    expect( @creneau.salles ).to be_empty
    expect( @creneau.cours ).to be_empty
    expect( @creneau.devoirs ).to be_empty
    expect( @creneau.debut.iso8601.split('+').first.split('T').last ).to eq '14:00:00'
    expect( @creneau.fin.iso8601.split('+').first.split('T').last ).to eq '15:00:00'
    expect( @creneau.jour_de_la_semaine ).to eq @jour_de_la_semaine
    expect( @creneau.matiere_id ).to be_empty
    expect( @creneau.etablissement_id ).to eq @etablissement.id
  end

  it 'def toggle_deleted( date_suppression )' do
    date_suppression = Time.now

    @creneau.toggle_deleted( date_suppression )

    expect( @creneau.deleted ).to be true
    expect( @creneau.date_suppression ).to eq date_suppression

    @creneau.toggle_deleted( date_suppression )

    expect( @creneau.deleted ).to be false
    expect( @creneau.date_suppression ).to be nil
  end

  it 'def similaires( debut, fin, user )' do
    expect( 1 ).to eq 1
    STDERR.puts 'FIXME'
  end

  it 'def modifie( params ) # hours as string' do
    @creneau.modifie( heure_debut: '12:34',
                      heure_fin: '23:45' )
    expect( @creneau.debut.iso8601.split('+').first.split('T').last ).to eq '12:34:00'
    expect( @creneau.fin.iso8601.split('+').first.split('T').last ).to eq '23:45:00'
  end

  it 'def modifie( params ) # hours as Time' do
    @creneau.modifie( heure_debut: Time.parse( '10:02' ),
                      heure_fin: Time.parse( '21:09' ) )
    expect( @creneau.debut.iso8601.split('+').first.split('T').last ).to eq '10:02:00'
    expect( @creneau.fin.iso8601.split('+').first.split('T').last ).to eq '21:09:00'
  end

  it 'def modifie( params ) # change matiere' do
    @creneau.modifie( matiere_id: 'dummy_matiere_id' )
    expect( @creneau.matiere_id ).to eq 'dummy_matiere_id'
  end

  it 'def modifie( params ) # change day' do
    @creneau.modifie( jour_de_la_semaine: @jour_de_la_semaine + 1 )
    expect( @creneau.jour_de_la_semaine ).to eq @jour_de_la_semaine + 1
  end

  it 'def modifie( params ) # add enseignant' do
    @creneau.modifie( enseignant_id: 'VZZ99999' )
    expect( @creneau.enseignants.count ).to eq 1
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ] ).to_not be nil
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ].semaines_de_presence ).to eq 2**52 - 1
  end

  it 'def modifie( params ) # change enseignant' do
    @creneau.modifie( enseignant_id: 'VZZ99999' )
    expect( @creneau.enseignants.count ).to eq 1
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ] ).to_not be nil
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ].semaines_de_presence ).to eq 2**52 - 1
    @creneau.modifie( enseignant_id: 'VZZ99999',
                      semaines_de_presence_enseignant: 123 )
    expect( @creneau.enseignants.count ).to eq 1
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ] ).to_not be nil
    expect( CreneauEmploiDuTempsEnseignant[ creneau_emploi_du_temps_id: @creneau.id,
                                            enseignant_id: 'VZZ99999' ].semaines_de_presence ).to eq 123
  end

  it 'def modifie( params ) # add regroupement' do
    @creneau.modifie( regroupement_id: 999_999 )
    expect( @creneau.regroupements.count ).to eq 1
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ] ).to_not be nil
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ].semaines_de_presence ).to eq 2**52 - 1
  end

  it 'def modifie( params ) # change regroupement' do
    @creneau.modifie( regroupement_id: 999_999 )
    expect( @creneau.regroupements.count ).to eq 1
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ] ).to_not be nil
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ].semaines_de_presence ).to eq 2**52 - 1
    @creneau.modifie( regroupement_id: 999_999,
                      semaines_de_presence_regroupement: 123)
    expect( @creneau.regroupements.count ).to eq 1
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ] ).to_not be nil
    expect( CreneauEmploiDuTempsRegroupement[ creneau_emploi_du_temps_id: @creneau.id,
                                              regroupement_id: 999_999 ].semaines_de_presence ).to eq 123
  end

  it 'def modifie( params ) # add salle' do
    @creneau.modifie( salle_id: @salle.id )
    expect( @creneau.salles.count ).to eq 1
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ] ).to_not be nil
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ].semaines_de_presence ).to eq 2**52 - 1
  end

  it 'def modifie( params ) # change salle' do
    @creneau.modifie( salle_id: @salle.id )
    expect( @creneau.salles.count ).to eq 1
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ] ).to_not be nil
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ].semaines_de_presence ).to eq 2**52 - 1
    @creneau.modifie( salle_id: @salle.id,
                      semaines_de_presence_salle: 123)
    expect( @creneau.salles.count ).to eq 1
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ] ).to_not be nil
    expect( CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: @creneau.id,
                                       salle_id: @salle.id ].semaines_de_presence ).to eq 123
  end
end
