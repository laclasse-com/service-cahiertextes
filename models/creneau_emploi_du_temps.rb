require_relative '../lib/utils/holidays'

module SemainierMixin
  def present_pour_la_semaine?( semaine )
    semainier[semaine] == 1
  end
end

class CreneauEmploiDuTempsSalle < Sequel::Model( :creneaux_emploi_du_temps_salles )
  unrestrict_primary_key
  include SemainierMixin

  many_to_one :creneau_emploi_du_temps
  many_to_one :salle
end

class CreneauEmploiDuTemps < Sequel::Model( :creneaux_emploi_du_temps )
  many_to_many :salles, class: :Salle, join_table: :creneaux_emploi_du_temps_salles
  one_to_many :cours, class: :Cours
  one_to_many :devoirs
  many_to_one :structures, class: :Structure, key: :structure_id
  many_to_one :import, class: :Import, key: :import_id

  def toggle_deleted( date_suppression )
    update( deleted: !deleted, date_suppression: deleted ? nil : date_suppression )

    save
  end

  def to_hash
    h = super
    h.each { |k, v| h[k] = v.iso8601 if v.is_a?( Time ) }

    h
  end

  def detailed( _date_debut, _date_fin, details )
    h = to_hash

    details.each { |detail| h[ detail.to_sym ] = send( detail ) if self.class.method_defined?( detail ) }

    h
  end

  def duplicates
    CreneauEmploiDuTemps
      .select_append( :creneaux_emploi_du_temps__id___id )
      .where( Sequel.~( creneaux_emploi_du_temps__id: id ) )
      .where( matiere_id: matiere_id )
      .where( jour_de_la_semaine: jour_de_la_semaine )
      .where( regroupement_id: regroupement_id )
      .where( semainier: semainier )
      .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
      .where( deleted: false )
  end

  # attach cours and devoirs to this creneau and destroy other_creneau
  def merge( creneau_id )
    other_creneau = CreneauEmploiDuTemps[creneau_id]
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

  def similaires( groups_ids, date_debut, date_fin )
    date_debut = Date.parse( date_debut )
    date_fin = Date.parse( date_fin )
    query = CreneauEmploiDuTemps.where( matiere_id: matiere_id )
                                .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                                .where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" ) )

    query = query.where( regroupement_id: groups_ids ) unless groups_ids.nil?

    query.all
         .map do |c|
      ( date_debut .. date_fin )
        .select { |day| day.wday == c.jour_de_la_semaine }
        .map do |jour|
        next unless c.semainier[jour.cweek] == 1
        { id: c.id,
          creneau_emploi_du_temps_id: c.id,
          start: Time.new( jour.year, jour.month, jour.mday, c.debut.hour, c.debut.min ).iso8601,
          end: Time.new( jour.year, jour.month, jour.mday, c.fin.hour, c.fin.min ).iso8601,
          heure_debut: Time.new( jour.year, jour.month, jour.mday, c.debut.hour, c.debut.min ).iso8601,
          heure_fin: Time.new( jour.year, jour.month, jour.mday, c.fin.hour, c.fin.min ).iso8601,
          has_cours: c.cours.count { |cours| cours.date_cours == jour } > 0,
          jour_de_la_semaine: c.jour_de_la_semaine,
          matiere_id: c.matiere_id,
          regroupement_id: c.regroupement_id,
          semainier: c.semainier }
      end
    end
         .flatten
         .compact
  end

  def update_salle( salle_id, semainier_salle )
    creneau_salle = CreneauEmploiDuTempsSalle[creneau_emploi_du_temps_id: id, salle_id: salle_id]
    if creneau_salle.nil?
      salle = Salle[salle_id]
      return nil if salle.nil?

      add_salle( salle )

      creneau_salle = CreneauEmploiDuTempsSalle[creneau_emploi_du_temps_id: id, salle_id: salle_id]
    end

    creneau_salle.update( semainier: semainier_salle ) unless semainier_salle.nil?
  end

  def modifie( params )
    update( debut: params['heure_debut'] ) if params.key?( 'heure_debut' )
    update( fin: params['heure_fin'] ) if params.key?( 'heure_fin' )

    update( debut: params['debut'] ) if params.key?( 'debut' )
    update( fin: params['fin'] ) if params.key?( 'fin' )

    update( matiere_id: params['matiere_id'] ) if params.key?( 'matiere_id' )
    update( import_id: params['import_id'] ) if params.key?( 'import_id' )
    update( jour_de_la_semaine: params['jour_de_la_semaine'] ) if params.key?( 'jour_de_la_semaine' )
    update( regroupement_id: params['regroupement_id'] ) if params.key?( 'regroupement_id' )
    update( semainier: params['semainier_regroupement'] ) if params.key?( 'semainier_regroupement' )

    save

    update_salle( params['salle_id'], params['semainier_salle'] ) if params.key?( 'salle_id' )
  rescue StandardError => e
    puts "Can't do that with #{self}"
    puts e.message
    puts e.backtrace
  end

  def deep_destroy
    remove_all_cours
    remove_all_devoirs
    remove_all_salles

    destroy
  end
end
