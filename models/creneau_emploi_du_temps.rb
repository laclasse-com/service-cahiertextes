# -*- coding: utf-8 -*-

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end
end

class CreneauEmploiDuTempsSalle < Sequel::Model( :creneaux_emploi_du_temps_salles )
  unrestrict_primary_key
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
  many_to_one :salle
end

class CreneauEmploiDuTempsEnseignant < Sequel::Model( :creneaux_emploi_du_temps_enseignants )
  unrestrict_primary_key
  include SemainesDePresenceMixin

  many_to_one :creneau_emploi_du_temps
end

class CreneauEmploiDuTempsRegroupement < Sequel::Model( :creneaux_emploi_du_temps_regroupements )
  unrestrict_primary_key
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
              has_cours: c.cours.count { |cours| cours.date_cours == jour } > 0,
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

  def update_heure_debut( value )
    plage_horaire_debut = PlageHoraire.where( debut: value ).first
    if plage_horaire_debut.nil?
      plage_horaire_debut = PlageHoraire.create( label: '',
                                                 debut: value,
                                                 fin: value + 1800 )
    end
    update( debut: plage_horaire_debut.id )
  end

  def update_heure_fin( value )
    plage_horaire_fin = PlageHoraire.where( fin: value ).first
    if plage_horaire_fin.nil?
      plage_horaire_fin = PlageHoraire.create( label: '',
                                               debut: value - 1800,
                                               fin: value )
    end
    update( fin: plage_horaire_fin.id )
  end

  def update_semaines_de_presence_enseignant( value )
    ce = CreneauEmploiDuTempsEnseignant
         .where( enseignant_id: user[:uid] )
         .where( creneau_emploi_du_temps_id: params[:id] )
    ce.update( semaines_de_presence: value )
  end

  def update_semaines_de_presence_regroupement( regroupement_id, semaines_de_presence_regroupement )
    cr = CreneauEmploiDuTempsRegroupement
         .where( creneau_emploi_du_temps_id: id )
         .where( regroupement_id: regroupement_id)
    cr.update( semaines_de_presence: semaines_de_presence_regroupement ) unless cr.nil?
  end

  def update_regroupement( regroupement_id, previous_regroupement_id, semaines_de_presence_regroupement )
    if CreneauEmploiDuTempsRegroupement
       .where( creneau_emploi_du_temps_id: id )
       .where( regroupement_id: regroupement_id ).count < 1
      # 1. first remove previous créneau-regroupement association
      previous_creneau_regroupement = CreneauEmploiDuTemps.last.regroupements
                                      .find do |cr|
        cr.regroupement_id == previous_regroupement_id
      end
      previous_creneau_regroupement.destroy unless previous_creneau_regroupement.nil?

      # 2. create the new one
      CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
      cr = add_regroupement( regroupement_id: regroupement_id )
      CreneauEmploiDuTempsRegroupement.restrict_primary_key

      cr.update( semaines_de_presence: semaines_de_presence_regroupement ) if semaines_de_presence_regroupement
    end

    update_semaines_de_presence_regroupement( regroupement_id, semaines_de_presence_regroupement ) if semaines_de_presence_regroupement
  end

  def update_salle( salle_id, semaines_de_presence_salle )
    CreneauEmploiDuTempsSalle.unrestrict_primary_key
    cs = add_salle( salle_id: salle_id )
    CreneauEmploiDuTempsSalle.restrict_primary_key

    cs.update semaines_de_presence: semaines_de_presence_salle if semaines_de_presence_salle
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def modifie( params )
    update_heure_debut( params[:heure_debut] ) if params[:heure_debut]
    update_heure_fin( params[:heure_fin] ) if params[:heure_fin]
    update( matiere_id: params[:matiere_id] ) if params[:matiere_id]

    save

    CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
    add_enseignant( enseignant_id: params[:enseignant_id] ) if params[:enseignant_id]
    CreneauEmploiDuTempsEnseignant.restrict_primary_key
    update_semaines_de_presence_enseignant( params[:semaines_de_presence_enseignant] ) if params[:semaines_de_presence_enseignant]

    update_regroupement( params[:regroupement_id], params[:previous_regroupement_id], params[:semaines_de_presence_regroupement] ) unless params[:regroupement_id].nil? || params[:regroupement_id] == 'undefined'

    update_salle( params[:salle], params[:semaines_de_presence_salle] ) if params[:salle_id]
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
end
