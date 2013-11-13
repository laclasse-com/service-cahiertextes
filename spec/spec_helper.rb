# -*- coding: utf-8 -*-
require 'rubygems'

ENV["RACK_ENV"] ||= 'test'

require 'rack/test'
require 'sequel'
require 'tsort'

require_relative '../config/environment'
require_relative '../config/database'

require_relative '../app'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec

  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

# # Example usage.
# cleaner = TableCleaner.new DB, [:spatial_ref_sys]
# cleaner.clean
class TableCleaner
  def initialize db, excluded_tables
    @db = db
    @excluded_tables = excluded_tables
  end

  def clean
    @db.transaction do
      tables_to_clean do |t|
        @db[t].delete
      end
    end
  end

  private
  include TSort

  def tables_to_clean &block
    tsort.reverse.each &block
  end

  def tsort_each_node &block
    @db.tables.each do |t|
      block.call t unless @excluded_tables.include? t
    end
  end

  def tsort_each_child table, &block
    @db.foreign_key_list(table).each do |fk|
      block.call fk[:table] unless @excluded_tables.include? fk[:table]
    end
  end
end

def load_test_data
  system 'mysql -u ' + DB_CONFIG[:user] + ' -p' + DB_CONFIG[:password] + ' ' + DB_CONFIG[:name] + ' < spec/fixtures/db_dump.sql'
end

def generate_test_data
  STDERR.puts 'Remplissage des Cahiers de textes'
  [ [ 'DS', 'Devoir surveillé' ],
    [ 'DM', 'Devoir à la maison' ],
    [ 'Leçon', 'Leçon à apprendre' ],
    [ 'Exposé', 'Exposé à préparer' ],
    [ 'Recherche', 'Recherche à faire' ],
    [ 'Exercice', 'Exercice à faire' ] ].each { |type|
    TypeDevoir.create(label: type[0],
                      description: type[1] )
    STDERR.putc '.'
  }

  CahierDeTextes.all.each { |cahier_de_textes|
    12.times {
      |month|
      rand(2..4).times {
        creneau = CreneauEmploiDuTempsEnseignant.all.sample

        cours = Cours.create(cahier_de_textes_id: cahier_de_textes.id,
                             creneau_emploi_du_temps_id: creneau.creneau_emploi_du_temps_id,
                             date_cours: '2013-' + (month + 1).to_s + '-29',
                             contenu: 'Exemple de séquence pédagogique.',
                             enseignant_id: creneau.enseignant_id )
        STDERR.putc '.'

        if rand > 0.25
          creneau_emploi_du_temps = CreneauEmploiDuTemps
            .where(matiere_id: CreneauEmploiDuTemps[ creneau.creneau_emploi_du_temps_id ].matiere_id)
            .where(jour_de_la_semaine: Date.tomorrow.wday)
            .join(:creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :id)
            .where(enseignant_id: cours.enseignant_id)
            .first                # FIXME: arbitrairement on choisi d'attacher le devoir au premier créneau

          Devoir.create(cours_id: cours.id,
                        type_devoir_id: TypeDevoir.all.sample.id,
                        creneau_emploi_du_temps_id: creneau_emploi_du_temps.id,
                        date_due: Date.tomorrow,
                        contenu: 'Exemple de devoir.',
                        temps_estime: rand(0..120) ) unless creneau_emploi_du_temps.nil?
          STDERR.putc '.'
        end
      }
    }
  }
  STDERR.puts
end
