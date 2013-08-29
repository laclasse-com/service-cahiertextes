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
cahier_de_textes.insert(regroupement_id: 1, debut_annee_scolaire: Time.now, fin_annee_scolaire: Time.now, date_creation: Time.now, label: 'Oh le joli cahier de textes!')
cahier_de_textes.insert(regroupement_id: 2, debut_annee_scolaire: Time.now, fin_annee_scolaire: Time.now, date_creation: Time.now, label: 'Oh le joli cahier de textes!')
cahier_de_textes.insert(regroupement_id: 3, debut_annee_scolaire: Time.now, fin_annee_scolaire: Time.now, date_creation: Time.now, label: 'Oh le joli cahier de textes!')

ressources = DB[:ressource]
ressources.insert(label: 'test 1', doc_id: 983456)
ressources.insert(label: 'test 2', doc_id: 56324)
ressources.insert(label: 'test 3', doc_id: 983)
ressources.insert(label: 'test 4', doc_id: 67265)

cours = DB[:cours]
cours.insert(cahier_de_textes_id: 1, creneau_emploi_du_temps_id: 1, enseignant_id: 2, date_cours: Time.now, contenu: '<em>Alors là</em><br>C\'était absolument fascinant' )
cours.insert(cahier_de_textes_id: 2, creneau_emploi_du_temps_id: 11, enseignant_id: 2, date_cours: Time.now, contenu: '<em>Alors là</em><br>C\'était absolument fascinant' )
cours.insert(cahier_de_textes_id: 3, creneau_emploi_du_temps_id: 6, enseignant_id: 2, date_cours: Time.now, contenu: '<em>Alors là</em><br>C\'était absolument fascinant' )

devoirs = DB[:devoir]
devoirs.insert(cours_id: 1, type_devoir_id: 3, contenu: 'faire le poirier 10 minutes', date_creation: Time.now)
