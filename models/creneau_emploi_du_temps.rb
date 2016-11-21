# -*- coding: utf-8 -*-

require_relative '../lib/utils/holidays'

module SemainesDePresenceMixin
  def present_pour_la_semaine?( semaine )
    semaines_de_presence[ semaine ] == 1
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
  one_to_many :regroupements, class: :CreneauEmploiDuTempsRegroupement, table: :creneaux_emploi_du_temps_regroupements
  one_to_many :enseignants, class: :CreneauEmploiDuTempsEnseignant, table: :creneaux_emploi_du_temps_enseignants
  many_to_many :salles, class: :Salle, join_table: :creneaux_emploi_du_temps_salles

  one_to_many :cours, class: :Cours
  one_to_many :devoirs

  many_to_one :etablissement, class: :Etablissement, key: :etablissement_id

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
    h[:vierge] = cours.count.zero? && devoirs.count.zero?
    if expand
      h[:cours] = Cours.where( creneau_emploi_du_temps_id: id ).where( deleted: false ).where( date_cours: debut .. fin )
      h[:devoirs] = Devoir.where( creneau_emploi_du_temps_id: id ).where( date_due: debut .. fin )
    end

    h
  end

  def duplicates
    CreneauEmploiDuTemps
      .select_append( :creneaux_emploi_du_temps__id___id )
      .where( Sequel.~( creneaux_emploi_du_temps__id: id ) )
      .association_join( :regroupements )
      .select_append( :regroupements__semaines_de_presence___semainier_regroupement )
      .association_join( :enseignants )
      .select_append( :enseignants__semaines_de_presence___semainier_enseignant )
      .where( matiere_id: matiere_id )
      .where( jour_de_la_semaine: jour_de_la_semaine )
      .where( regroupements__regroupement_id: regroupements.map( &:regroupement_id ) )
      .where( enseignants__enseignant_id: enseignants.map( &:enseignant_id ) )
      .where( regroupements__semaines_de_presence: regroupements.map( &:semaines_de_presence ) )
      .where( enseignants__semaines_de_presence: enseignants.map( &:semaines_de_presence ) )
      .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{Utils.date_rentree}'" )
      .where( deleted: false )
  end

  # attach cours and devoirs to this creneau and destroy other_creneau
  def merge( creneau_id )
    other_creneau = CreneauEmploiDuTemps[ creneau_id ]
    return false if other_creneau.nil?

    other_creneau.cours.each do |cours|
      cours.update( creneau_emploi_du_temps_id: id )
      cours.save
    end
    other_creneau.devoirs.each do |devoir|
      devoir.update( creneau_emploi_du_temps_id: id )
      devoir.save
    end
  end

  def merge_twins
    return [] if deleted

    duplicates.select(:creneaux_emploi_du_temps__id)
              .naked
              .all
              .map do |twin_id|
      twin = CreneauEmploiDuTemps[ twin_id[:id] ]
      next if twin.deleted

      merge( twin.id )

      twin.id
    end
  end

  def merge_and_destroy_twins( truly_destroy = false )
    merge_twins.map do |twin_id|
      if truly_destroy
        CreneauEmploiDuTemps[twin_id].deep_destroy
      else
        CreneauEmploiDuTemps[twin_id].toggle_deleted( Time.now )
      end

      twin_id
    end
  end

  def similaires( date_debut, date_fin, user )
    # .where { date_creation >= 1.year.ago }
    # .where { !deleted || date_suppression >= fin }
    CreneauEmploiDuTemps
      .association_join( :enseignants )
      .where( enseignant_id: user[:uid] )
      .where( matiere_id: matiere_id )
      .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{Utils.date_rentree}'" )
      .where( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" )
      .all
      .map do |c|
      ( date_debut .. date_fin )
        .reject { |day| day.wday != c.jour_de_la_semaine }
        .map do |jour|
        c.regroupements.map do |regroupement|
          next unless regroupement.semaines_de_presence[ jour.cweek ] == 1
          { id: c.id,
            creneau_emploi_du_temps_id: c.id,
            start: Time.new( jour.year,
                             jour.month,
                             jour.mday,
                             c.debut.hour,
                             c.debut.min ).iso8601,
            end: Time.new( jour.year,
                           jour.month,
                           jour.mday,
                           c.fin.hour,
                           c.fin.min ).iso8601,
            heure_debut: Time.new( jour.year,
                                   jour.month,
                                   jour.mday,
                                   c.debut.hour,
                                   c.debut.min ).iso8601,
            heure_fin: Time.new( jour.year,
                                 jour.month,
                                 jour.mday,
                                 c.fin.hour,
                                 c.fin.min ).iso8601,
            has_cours: c.cours.count { |cours| cours.date_cours == jour } > 0,
            jour_de_la_semaine: c.jour_de_la_semaine,
            matiere_id: c.matiere_id,
            regroupement_id: regroupement.regroupement_id,
            semaines_de_presence: regroupement.semaines_de_presence,
            vierge: cours.count.zero? && devoirs.count.zero? }
        end
      end
    end
      .flatten
      .compact
  end

  def update_semaines_de_presence_enseignant( enseignant_id, semaines_de_presence_enseignant )
    CreneauEmploiDuTempsEnseignant.where( enseignant_id: enseignant_id, creneau_emploi_du_temps_id: id )
                                  .update( semaines_de_presence: semaines_de_presence_enseignant )
  end

  def update_semaines_de_presence_regroupement( regroupement_id, semaines_de_presence_regroupement )
    CreneauEmploiDuTempsRegroupement.where( creneau_emploi_du_temps_id: id, regroupement_id: regroupement_id)
                                    .update( semaines_de_presence: semaines_de_presence_regroupement )
  end

  def update_regroupement( regroupement_id, previous_regroupement_id, semaines_de_presence_regroupement )
    return unless CreneauEmploiDuTempsRegroupement.where( creneau_emploi_du_temps_id: id, regroupement_id: regroupement_id ).count < 1

    CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
    cr = add_regroupement( regroupement_id: regroupement_id )
    cr.update( semaines_de_presence: semaines_de_presence_regroupement ) unless semaines_de_presence_regroupement.nil?
    CreneauEmploiDuTempsRegroupement.restrict_primary_key

    CreneauEmploiDuTempsRegroupement.where( creneau_emploi_du_temps_id: id, regroupement_id: previous_regroupement_id ).destroy
  end

  def update_salle( salle_id, semaines_de_presence_salle )
    creneau_salle = CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: id, salle_id: salle_id ]
    if creneau_salle.nil?
      salle = Salle[ salle_id ]
      return nil if salle.nil?

      add_salle( salle )

      creneau_salle = CreneauEmploiDuTempsSalle[ creneau_emploi_du_temps_id: id, salle_id: salle_id ]
    end

    creneau_salle.update( semaines_de_presence: semaines_de_presence_salle ) unless semaines_de_presence_salle.nil?
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def modifie( params )
    update( debut: params[:heure_debut] ) if params.key?( :heure_debut )
    update( fin: params[:heure_fin] ) if params.key?( :heure_fin )
    update( matiere_id: params[:matiere_id] ) if params.key?( :matiere_id )
    update( jour_de_la_semaine: params[:jour_de_la_semaine] ) if params.key?( :jour_de_la_semaine )

    save

    if params.key?( :enseignant_id ) && enseignants.count { |e| e[:enseignant_id] == params[:enseignant_id] }.zero?
      CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
      add_enseignant( enseignant_id: params[:enseignant_id] )
      CreneauEmploiDuTempsEnseignant.restrict_primary_key
    end
    update_semaines_de_presence_enseignant( params[:enseignant_id], params[:semaines_de_presence_enseignant] ) if params.key?( :semaines_de_presence_enseignant )

    update_regroupement( params[:regroupement_id], params[:previous_regroupement_id], params[:semaines_de_presence_regroupement] ) if params.key?( :regroupement_id ) && !params[:regroupement_id].nil? && params[:regroupement_id] != -1
    update_semaines_de_presence_regroupement( params[:regroupement_id], params[:semaines_de_presence_regroupement] ) if params.key?( :semaines_de_presence_regroupement )

    update_salle( params[:salle_id], params[:semaines_de_presence_salle] ) if params.key?( :salle_id )
  rescue StandardError => e
    puts "Can't do that with #{self}"
    puts e.message
    puts e.backtrace
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def deep_destroy
    remove_all_cours
    remove_all_devoirs
    regroupements.map( &:destroy )
    enseignants.map( &:destroy )
    remove_all_salles

    destroy
  end
end
