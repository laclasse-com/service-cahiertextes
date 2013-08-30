#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'sequel'

require_relative '../../config/database'
require_relative '../../models/models'

types_devoir = DB[:type_devoir]
types_devoir.insert(label: 'DS', description: 'Devoir surveillé')
types_devoir.insert(label: 'DM', description: 'Devoir à la maison')
types_devoir.insert(label: 'Leçon', description: 'Leçon à apprendre')
types_devoir.insert(label: 'Exposé', description: 'Exposé à préparer')
types_devoir.insert(label: 'Recherche', description: 'Recherche à faire')
types_devoir.insert(label: 'Exercice', description: 'Exercice à faire')

cahier_de_textes = DB[:cahier_de_textes]
5.times { |i|
  cahier_de_textes.insert(regroupement_id: i,
                          debut_annee_scolaire: Time.now,
                          fin_annee_scolaire: Time.now,
                          date_creation: Time.now,
                          label: 'Oh le joli cahier de textes!')
}

ressources = DB[:ressource]
9.times { |i|
  ressources.insert(label: 'test #{i}',
                    url: "http://bla/#{i}")
}

cours = DB[:cours]
13.times { |i|
  cours.insert(cahier_de_textes_id: CahierDeTextes.all[ rand(0..CahierDeTextes.count-1) ][:id],
               creneau_emploi_du_temps_id: CreneauEmploiDuTemps.all[ rand(0..CreneauEmploiDuTemps.count-1) ][:id],
               enseignant_id: 2,
               date_cours: Time.now,
               contenu: '<em>Alors là</em><br>C\'était absolument fascinant')
}

devoirs = DB[:devoir]
8.times { |i|
  devoirs.insert(cours_id: Cours.all[ rand(0..Cours.count-1) ][:id],
                 type_devoir_id: TypeDevoir.all[ rand(0..TypeDevoir.count-1) ][:id],
                 contenu: 'faire le poirier 10 minutes',
                 date_creation: Time.now)
}
