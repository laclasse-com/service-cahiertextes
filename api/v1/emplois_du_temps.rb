# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire'

module CahierDeTextesAPI
  module V1
    class EmploisDuTempsAPI < Grape::API

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date

        optional :uai
        optional :uid
      }
      get '/du/:debut/au/:fin' do
        params[:debut] = Date.parse( params[:debut].iso8601 )
        params[:fin] = Date.parse( params[:fin].iso8601 )

        user_annuaire = Annuaire.get_user( user.uid )
        user_annuaire['profil_actif'] = user_annuaire['profils'].select { |p| p['actif'] }.first

        if %w( EVS DIR ).include?( user_annuaire['profil_actif']['profil_id'] )
          regroupements_annuaire = Annuaire.get_etablissement_regroupements( user_annuaire['profil_actif']['etablissement_code_uai'] )
        else
          error!( '401 Unauthorized', 401 ) unless !params[:uid] || %w( TUT ).include?( user_annuaire['profil_actif']['profil_id'] ) && user_annuaire['enfants'].select { |e| e['enfant']['id_ent'] == params[:uid] }.length == 1

          uid = params[:uid] ? params[:uid] : user.uid
          regroupements_annuaire = Annuaire.get_user_regroupements( uid )
        end

        regroupements_ids = regroupements_annuaire['classes']
                            .concat( regroupements_annuaire['groupes_eleves'] )
                            .concat( regroupements_annuaire['groupes_libres'] )

        regroupements_ids = regroupements_ids.reject { |regroupement| regroupement['etablissement_code'] != params[:uai] if params[:uai] } unless %w( EVS DIR ).include?( user_annuaire['profil_actif']['profil_id'] )

        regroupements_ids = regroupements_ids
                            .map do |regroupement|
          if regroupement.key? 'classe_id'
            regroupement['classe_id']
          elsif regroupement.key? 'groupe_id'
            regroupement['groupe_id']
          elsif regroupement.key? 'id'
            regroupement['id']
          end
        end
                            .uniq

        date_rentree = Date.parse( "#{Date.today.month > 8 ? Date.today.year : Date.today.year - 1}-09-01" )
        
        # Nota Bene: creneau[:semaines_de_presence][ 1 ] == première semaine de janvier
        CreneauEmploiDuTemps
          .association_join( :enseignants )
          .association_join( :regroupements )
          .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{date_rentree}'" )
          .where( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{params[:fin]}')" )
          .where( regroupement_id: regroupements_ids )
          .all
          .map do |creneau|

          ( params[:debut] .. params[:fin] )
            .select { |day| day.wday == creneau.jour_de_la_semaine } # only the same weekday as the creneau
            .map do |jour|

              if creneau[:semaines_de_presence][ jour.cweek ] == 1
                cahier_de_textes = CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first
                cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                          regroupement_id: creneau[:regroupement_id] ) if cahier_de_textes.nil?

                # STDERR.puts "Séquences pédagogiques multiples associées au créneau #{creneau.id}" if creneau.cours.length > 1

                { regroupement_id: creneau[ :regroupement_id ],
                  enseignant_id: creneau[ :enseignant_id ],
                  creneau_emploi_du_temps_id: creneau.id,
                  matiere_id: creneau.matiere_id,
                  cahier_de_textes_id: cahier_de_textes.id,  # utilisé lors de la création d'un cours côté client
                  start: Time.new( jour.year, jour.month, jour.mday, creneau.plage_horaire_debut.debut.hour, creneau.plage_horaire_debut.debut.min ).iso8601,
                  end: Time.new( jour.year, jour.month, jour.mday, creneau.plage_horaire_fin.fin.hour, creneau.plage_horaire_fin.fin.min ).iso8601,
                  cours: creneau.cours.select { |cours| cours[:deleted] == false && cours.date_cours == jour }
                                      .map do |cours|
                    hcours = cours.to_hash
                    hcours[:ressources] = cours.ressources.map { |rsrc| rsrc.to_hash }

                    hcours
                  end
                                      .first,
                  devoirs: creneau.devoirs.select { |devoir| devoir[:deleted] == false && devoir.date_due == jour }
                                          .map do |devoir|
                    hdevoir = devoir.to_hash
                    hdevoir[:ressources] = devoir.ressources.map { |rsrc| rsrc.to_hash }
                    hdevoir[:type_devoir_description] = devoir.type_devoir.description
                    hdevoir[:fait] = devoir.fait_par?( user.uid )

                    hdevoir
                  end
                }
              else
                next
              end
            end
        end
          .flatten
          .compact
      end
    end
  end
end
