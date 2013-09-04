# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    TableCleaner.new( DB, [] ).clean

    cahier_de_textes = CahierDeTextes.create(regroupement_id: 1,
                                             date_creation: Time.now,
                                             deleted: false)
    plage_horaire_debut = PlageHoraire.create(label: 'test_debut',
                                              debut: '08:30:00',
                                              fin: '09:00:00')
    plage_horaire_fin = PlageHoraire.create(label: 'test_fin',
                                            debut: '09:30:00',
                                            fin: '10:00:00')
    creneau_emploi_du_temps = CreneauEmploiDuTemps.create(debut: plage_horaire_debut.id,
                                                          fin: plage_horaire_fin.id)
    type_devoir = TypeDevoir.create(label: 'RSpec',
                                    description: 'Type de devoir tout spécial pour rspec')

    cours = Cours.create(cahier_de_textes_id: cahier_de_textes.id,
                         creneau_emploi_du_temps_id: creneau_emploi_du_temps.id,
                         date_cours: '2013-08-29',
                         contenu: 'Exemple de séquence pédagogique.' )
    Devoir.create(cours_id: cours.id,
                  type_devoir_id: type_devoir.id,
                  date_due: Time.now,
                  contenu: 'Exemple de devoir.',
                  temps_estime: rand(0..120) )
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Cours
  ############ GET ############
  it 'valide une séquence pédagogique' do
    cours = Cours.last
    cours.date_validation = nil
    cours.save

    put "/cours/#{cours.id}/valide", {}
    last_response.status.should == 200

    cours2 = Cours[ cours.id ]

    cours2.date_validation.should_not equal nil
  end
  # }}}

end
