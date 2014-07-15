# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire'

module CahierDeTextesAPI
  module V0
    class EmploisDuTempsAPI < Grape::API

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date
        optional :uai
      }
      get '/du/:debut/au/:fin' do
        params[:debut] = Date.parse( params[:debut].iso8601 )
        params[:fin] = Date.parse( params[:fin].iso8601 )
        weeks =  ( params[:debut] .. params[:fin] ).map { |d| d.cweek }.uniq

        regroupements_ids = Annuaire.get_user_regroupements( user.uid )['classes']
                                    .reject { |classe| classe['etablissement_code'] != params[:uai] if params[:uai] }
                                    .map    { |classe| classe['classe_id'] }
                                    .uniq

        # FIXME: creneau[:semaines_de_presence][ 1 ] == première semaine de janvier ?
        # FIXME: Un creneau "deleted" ne doit pas empecher les saisies déjà effectuée d'apparaitre
        # Soit le créneau est marqué deleted ET les dates debut et fin sont antérieures à la date deleted
        # Soit le créneau n'est pas marqué deleted et pas de restriction sur les dates debut et fin
        CreneauEmploiDuTemps
          .association_join( :regroupements )
          .association_join( :enseignants )
          .where( "( (deleted = true and date_suppression <= #{params[:fin]}) or (deleted = false) )" )
          .where( regroupement_id: regroupements_ids )
          .all
          .select do |creneau| weeks.reduce( true ) { |a, e| a && creneau[:semaines_de_presence][ e ] == 1 } end
          .map do |creneau|
          plage_debut = PlageHoraire[ creneau.debut ].debut
          plage_fin = PlageHoraire[ creneau.fin ].fin

          # 1. récupération du cahier de textes
          cahier_de_textes = CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first

          # FIXME: hack un peu rapide et pas très propre !
          # À REFACTORER
          [
            ( params[:debut] .. params[:fin] )
            .reject { |day| day.wday != creneau.jour_de_la_semaine }
            .map do
              |jour|
              cours = {}
              devoirs = []

              # 2. récupération des cours
              Cours
                .where( creneau_emploi_du_temps_id: creneau.id )
                .where( cahier_de_textes_id: cahier_de_textes.id )
                .where( date_cours: jour )
                .where( deleted: false )
                .each do
                |le_cours|

               cours = le_cours.to_hash
               cours[:ressources] = le_cours.ressources.map { |rsrc| rsrc.to_hash }

               devoirs = Devoir
                 .where( cours_id: cours[:id] )
                 .where( deleted: false )
                 .all
                 .map do
                 |devoir|
                 hstart         = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].debut ].debut
                 hend           = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].fin ].fin
                 d              = devoir.to_hash
                 d[:type_devoir_description] = TypeDevoir[ devoir.type_devoir_id ].description
                 d[:ressources] = devoir.ressources.map { |rsrc| rsrc.to_hash }
                 d[:fait]       = devoir.fait_par?( user.uid )
                 d[:start]      = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hstart.hour, hstart.min ).iso8601
                 d[:end]        = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hend.hour, hend.min ).iso8601

                 d
               end
             end

             { cahier_de_textes_id: cahier_de_textes.id,
               regroupement_id: cahier_de_textes.regroupement_id,
               enseignant_id: creneau[:enseignant_id],
               creneau_emploi_du_temps_id: creneau.id,
               matiere_id: creneau.matiere_id,
               start: Time.new( jour.year, jour.month, jour.mday, plage_debut.hour, plage_debut.min ).iso8601,
               end: Time.new( jour.year, jour.month, jour.mday, plage_fin.hour, plage_fin.min ).iso8601,
               cours: cours,
               devoirs: devoirs
             }
           end,
           ( params[:debut] .. params[:fin] )
             .reject { |day| day.wday != creneau.jour_de_la_semaine }
             .map do
             |jour|
             Devoir
               .where( creneau_emploi_du_temps_id: creneau.id )
               .where( date_due: jour )
               .where( deleted: false )
               .all
               .map do
               |record|
               hstart         = PlageHoraire[ CreneauEmploiDuTemps[ record.creneau_emploi_du_temps_id ].debut ].debut
               hend           = PlageHoraire[ CreneauEmploiDuTemps[ record.creneau_emploi_du_temps_id ].fin ].fin
               devoir              = Devoir[ record.id ].to_hash
               devoir[:type_devoir_description] = TypeDevoir[ record.type_devoir_id ].description
               devoir[:ressources] = record.ressources.map { |rsrc| rsrc.to_hash }
               devoir[:fait]       = record.fait_par?( user.uid )
               devoir[:start]      = Time.new( record.date_due.year, record.date_due.month, record.date_due.mday, hstart.hour, hstart.min ).iso8601
               devoir[:end]        = Time.new( record.date_due.year, record.date_due.month, record.date_due.mday, hend.hour, hend.min ).iso8601

               if record.cours_id.nil?
                 cours = nil
               else
                 cours = Cours
                         .where( id: record.cours_id )
                         .where( cahier_de_textes_id: cahier_de_textes.id )
                         .where( deleted: false )
                         .first
               end

               unless cours.nil?
                 jour_cours = cours.date_cours
                 { cahier_de_textes_id: cahier_de_textes.id,
                   regroupement_id: cahier_de_textes.regroupement_id,
                   enseignant_id: creneau[:enseignant_id],
                   creneau_emploi_du_temps_id: creneau.id,
                   matiere_id: creneau.matiere_id,
                   start: Time.new( jour_cours.year, jour_cours.month, jour_cours.mday, plage_debut.hour, plage_debut.min ).iso8601,
                   end: Time.new( jour_cours.year, jour_cours.month, jour_cours.mday, plage_fin.hour, plage_fin.min ).iso8601,
                   cours: cours,
                   devoirs: [ devoir ]
                 }
               end
             end

           end
          ]
        end
          .flatten
          .compact
          .uniq do |record|
          { creneau_emploi_du_temps_id: record[:cours] == {} && record[:devoirs] == [] ? record[:creneau_emploi_du_temps_id] : nil,
            cours_id: record[:cours] == {} ? nil : record[:cours][:id],
            devoirs_ids: record[:devoirs].map { |devoir| devoir[:id] } }
        end

      end
    end
  end
end
