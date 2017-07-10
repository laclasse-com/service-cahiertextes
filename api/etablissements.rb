# -*- coding: utf-8 -*-

require_relative '../lib/utils/date_rentree'

module CahierDeTextesApp
  class EtablissementsAPI < Grape::API
    format :json

    before  do
      user_needs_to_be( %w( DIR ENS DOC ) )
    end

    desc 'que connait le CTXT d\'un établissement'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'
    end
    get '/:uai' do
      etablissement = Etablissement[uai: params[:uai]]

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      hetablissement = etablissement.to_hash
      # .where { date_creation >= 1.year.ago }
      hetablissement[:nb_creneaux] = CreneauEmploiDuTemps.where( etablissement_id: etablissement.id )
                                                         .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" )
                                                         .count
      hetablissement[:imports] = etablissement.imports
      hetablissement[:matchables] = etablissement.matchables

      hetablissement
    end

    desc 'création d\'un établissement'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'

      optional :debut_annee_scolaire, desc: 'Date de commencement de l\'année scolaire'
      optional :fin_annee_scolaire, desc: 'Date de fin de l\'année scolaire'
      optional :date_premier_jour_premiere_semaine, desc: 'Date du premier jour de la semaine de commencement de l\'année scolaire'
    end
    post '/:uai' do
      etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                               UAI: params[:uai] )

      etablissement.debut_annee_scolaire = params[:debut_annee_scolaire] if params.key?( :debut_annee_scolaire )
      etablissement.fin_annee_scolaire = params[:fin_annee_scolaire] if params.key?( :fin_annee_scolaire )
      etablissement.date_premier_jour_premiere_semaine = params[:date_premier_jour_premiere_semaine] if params.key?( :date_premier_jour_premiere_semaine )
      etablissement.save

      etablissement
    end

    desc 'mise à jour d\'un établissement'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'

      optional :debut_annee_scolaire, desc: 'Date de commencement de l\'année scolaire'
      optional :fin_annee_scolaire, desc: 'Date de fin de l\'année scolaire'
      optional :date_premier_jour_premiere_semaine, desc: 'Date du premier jour de la semaine de commencement de l\'année scolaire'
    end
    put '/:uai' do
      etablissement = Etablissement[ uai: params[:uai] ]

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      etablissement.debut_annee_scolaire = params[:debut_annee_scolaire] if params.key?( :debut_annee_scolaire )
      etablissement.fin_annee_scolaire = params[:fin_annee_scolaire] if params.key?( :fin_annee_scolaire )
      etablissement.date_premier_jour_premiere_semaine = params[:date_premier_jour_premiere_semaine] if params.key?( :date_premier_jour_premiere_semaine )

      etablissement
    end

    desc 'statistiques des cahiers de textes par regroupements/mois/matières'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'
    end
    get '/:uai/statistiques/regroupements' do
      etablissement = Etablissement[ uai: params[:uai] ]

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      etablissement.statistiques_regroupements
    end

    desc 'statistiques du cahier de textes d\'un regroupement'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :regroupement_id, desc: 'identifiant annuaire de la classe'
    end
    get '/:uai/statistiques/regroupements/:regroupement_id' do
      cahier_de_textes = CahierDeTextes[ regroupement_id: params[:regroupement_id] ]

      error!( "Classe #{params[:regroupement_id]} inconnue dans l'établissement #{params[:uai]}", 404 ) if cahier_de_textes.nil?

      cahier_de_textes.statistiques
    end

    desc 'statistiques des cahiers de textes par enseignants/mois'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'
    end
    get '/:uai/statistiques/enseignants' do
      etablissement = Etablissement[ uai: params[:uai] ]

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      etablissement.statistiques_enseignants
    end

    desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
    params do
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
    end
    get '/:uai/statistiques/enseignants/:enseignant_id' do
      etablissement = Etablissement[ uai: params[:uai] ]

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      etablissement.saisies_enseignant( params[:enseignant_id] )
    end

    # # Salles
    # desc 'renvoi toutes les salles'
    # get '/:uai/salles' do
    #   etablissement = Etablissement[ uai: params[:uai] ]

    #   error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

    #   etablissement.salles
    # end

    # # Imports
    # desc 'renvoi tous les imports liés à l\'établissement'
    # get '/:uai/imports' do
    #   etablissement = Etablissement[ uai: params[:uai] ]

    #   error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

    #   etablissement.imports
    # end

    # # Matchables
    # desc 'renvoi tous les matchables liés à l\'établissement'
    # get '/:uai/imports' do
    #   etablissement = Etablissement[ uai: params[:uai] ]

    #   error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

    #   etablissement.matchables
    # end
  end
end
