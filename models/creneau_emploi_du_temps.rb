# -*- coding: utf-8 -*-

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end
end

class CreneauEmploiDuTempsSalle < Sequel::Model( :creneaux_emploi_du_temps_salles )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
  many_to_one :salle
end

class CreneauEmploiDuTempsEnseignant < Sequel::Model( :creneaux_emploi_du_temps_enseignants )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
end

class CreneauEmploiDuTempsRegroupement < Sequel::Model( :creneaux_emploi_du_temps_regroupements )
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
end

class CreneauEmploiDuTemps < Sequel::Model( :creneaux_emploi_du_temps )
  one_to_many :regroupements, class: :CreneauEmploiDuTempsRegroupement
  one_to_many :enseignants, class: :CreneauEmploiDuTempsEnseignant
  many_to_many :salles, class: :Salle, join_table: :creneaux_emploi_du_temps_salles

  one_to_many :cours, class: :Cours
  one_to_many :devoirs

  many_to_one :plage_horaire_debut, class: :PlageHoraire, key: :debut
  many_to_one :plage_horaire_fin, class: :PlageHoraire, key: :fin

  def toggle_deleted( date_suppression )
    if deleted
      update( deleted: false, date_suppression: nil )
    else
      update( deleted: true, date_suppression: date_suppression )
    end
    save
  end

  def to_deep_hash( debut, fin, expand )
    h = to_hash
    h[:regroupements] = regroupements
    h[:enseignants] = enseignants
    h[:salles] = salles
    h[:vierge] = cours.count == 0 && devoirs.count == 0
    if expand
      h[:cours] = Cours.where( creneau_emploi_du_temps_id: id ).where( deleted: false ).where( date_cours: debut .. fin )
      h[:devoirs] = Devoir.where( creneau_emploi_du_temps_id: id ).where( date_due: debut .. fin )
    end

    h
  end

  def similaires( debut, fin, user )
    CreneauEmploiDuTemps
      .association_join( :enseignants )
      .where( enseignant_id: user[:uid] )
      .where( matiere_id: matiere_id )
      .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{1.year.ago}'" )
      .where( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" )
      .all
      .map do |c|
      ( debut .. fin )
        .reject { |day| day.wday != c.jour_de_la_semaine }
        .map do |jour|
        c.regroupements.map do |regroupement|
          if regroupement.semaines_de_presence[ jour.cweek ] == 1
            { id: c.id,
              creneau_emploi_du_temps_id: c.id,
              start: Time.new( jour.year,
                               jour.month,
                               jour.mday,
                               c.plage_horaire_debut.debut.hour,
                               c.plage_horaire_debut.debut.min ).iso8601,
              end: Time.new( jour.year,
                             jour.month,
                             jour.mday,
                             c.plage_horaire_fin.fin.hour,
                             c.plage_horaire_fin.fin.min ).iso8601,
              heure_debut: Time.new( jour.year,
                                     jour.month,
                                     jour.mday,
                                     c.plage_horaire_debut.debut.hour,
                                     c.plage_horaire_debut.debut.min ).iso8601,
              heure_fin: Time.new( jour.year,
                                   jour.month,
                                   jour.mday,
                                   c.plage_horaire_fin.fin.hour,
                                   c.plage_horaire_fin.fin.min ).iso8601,
              has_cours: c.cours.select { |cours| cours.date_cours == jour }.count > 0,
              jour_de_la_semaine: c.jour_de_la_semaine,
              matiere_id: c.matiere_id,
              regroupement_id: regroupement.regroupement_id,
              semaines_de_presence: regroupement.semaines_de_presence,
              vierge: c.cours.count == 0 && c.devoirs.count == 0 }
          else
            next
          end
        end
      end
    end
      .flatten
      .compact
  end

  def modifie( params )
    if params[:heure_debut]
      plage_horaire_debut = PlageHoraire.where(debut: params[:heure_debut] ).first
      if plage_horaire_debut.nil?
        plage_horaire_debut = PlageHoraire.create( label: '',
                                                   debut: params[:heure_debut],
                                                   fin: params[:heure_debut] + 1800 )
      end
      update( debut: plage_horaire_debut.id )
    end

    if params[:heure_fin]
      plage_horaire_fin = PlageHoraire.where(fin: params[:heure_fin] ).first
      if plage_horaire_fin.nil?
        plage_horaire_fin = PlageHoraire.create( label: '',
                                                 debut: params[:heure_fin] - 1800,
                                                 fin: params[:heure_fin] )
      end
      update( fin: plage_horaire_fin.id )
    end

    update( matiere_id: params[:matiere_id] ) if params[:matiere_id]

    save

    if params[:enseignant_id]
      CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
      ce = add_enseignant( enseignant_id: params[:enseignant_id] )
      # ce.update( semaines_de_presence: params[:semaines_de_presence_enseignant] ) if params[:semaines_de_presence_enseignant]
      CreneauEmploiDuTempsEnseignant.restrict_primary_key
    end

    if params[:semaines_de_presence_enseignant]
      ce = CreneauEmploiDuTempsEnseignant
           .where( enseignant_id: user[:uid] )
           .where( creneau_emploi_du_temps_id: params[:id] )
      ce.update semaines_de_presence: params[:semaines_de_presence_enseignant]
    end

    unless params[:regroupement_id].nil? || params[:regroupement_id] == 'undefined'
      if CreneauEmploiDuTempsRegroupement
         .where( creneau_emploi_du_temps_id: params[:id] )
         .where( regroupement_id: params[:regroupement_id] ).count < 1
        CreneauEmploiDuTempsRegroupement.unrestrict_primary_key

        # 1. first remove previous créneau-regroupement association
        previous_creneau_regroupement = CreneauEmploiDuTemps.last.regroupements
                                        .select do |cr|
          cr.regroupement_id == params[:previous_regroupement_id]
        end.first
        previous_creneau_regroupement.destroy unless previous_creneau_regroupement.nil?

        # 2. create the new one
        cr = add_regroupement regroupement_id: params[:regroupement_id]
        cr.update semaines_de_presence: params[:semaines_de_presence_regroupement] if params[:semaines_de_presence_regroupement]

        CreneauEmploiDuTempsRegroupement.restrict_primary_key
      end
    end

    if params[:semaines_de_presence_regroupement] && params[:regroupement_id]
      cr = CreneauEmploiDuTempsRegroupement
           .where( creneau_emploi_du_temps_id: params[:id] )
           .where( regroupement_id: params[:regroupement_id])
      cr.update semaines_de_presence: params[:semaines_de_presence_regroupement] unless cr.nil?
    end

    if params[:salle_id]
      CreneauEmploiDuTempsSalle.unrestrict_primary_key
      cs = add_salle salle_id: params[:salle_id]
      cs.update semaines_de_presence: params[:semaines_de_presence_salle] if params[:semaines_de_presence_salle]
      CreneauEmploiDuTempsSalle.restrict_primary_key
    end
  end
end
