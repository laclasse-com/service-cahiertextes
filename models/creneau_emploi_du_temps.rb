# -*- coding: utf-8 -*-

require_relative '../lib/utils/holidays'

module SemainesDePresenceMixin
  def present_pour_la_semaine?( n )
    semaines_de_presence[n] == 1
  end

  def pretty_print_semainier
    semainier = semaines_de_presence.to_s( 2 )
                                    .reverse
                                    .rjust( 53, '0' )
    semainier = "#{semainier}#{semainier[semainier.length - 1]}"
    semainier[0] = ''
    semainier.split( '' )
             .map
             .with_index { |w, i| { week: i + 1, presence: w} }
             .group_by { |w| Date::MONTHNAMES[ Date.commercial( w[:week] < 30 ? 2016 : 2015, w[:week] ).month ] }
  end

  def all_school_year_semainier( zone, year_rentree )
    holidays_weeks = CahierDeTextesApp::Utils::Holidays.get( zone, year_rentree )
    (1..53).to_a.map { |i| holidays_weeks.include?( i ) ? '0' : '1' }.join.reverse.to_i( 2 )
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

  many_to_one :etablissement, class: :Etablissement, key: :etablissement_id
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
    h[:vierge] = cours.count.zero? && devoirs.count.zero?
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
          next unless regroupement.semaines_de_presence[ jour.cweek ] == 1
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
            vierge: cours.count.zero? && devoirs.count.zero? }
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
    params[:heure_debut] = Time.parse( params[:heure_debut] ) unless params[:heure_debut].is_a?( Time ) || !params.key?( :heure_debut )
    params[:heure_fin] = Time.parse( params[:heure_fin] ) unless params[:heure_fin].is_a?( Time ) || !params.key?( :heure_fin )

    update_heure_debut( params[:heure_debut] ) if params.key?( :heure_debut )
    update_heure_fin( params[:heure_fin] ) if params.key?( :heure_fin )
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
  rescue e
    puts "Can't do that with #{self}"
    puts e.message
    puts e.backtrace
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def deep_destroy
    enseignants.each(&:destroy)
    regroupements.each(&:destroy)
    salles.each(&:destroy)

    destroy
  end
end
