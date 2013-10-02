require 'rubygems'

ENV["RACK_ENV"] ||= 'test'

require 'rack/test'
require 'sequel'
require 'tsort'

require_relative '../config/environment'
require_relative '../config/database'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
end

require_relative '../app'

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

  12.times {
    |month|
    rand(2..4).times {
      CreneauEmploiDuTempsEnseignant.select( :creneau_emploi_du_temps_id, :enseignant_id ).limit( 32 ).each {
        |item|
        cours = Cours.create(cahier_de_textes_id: CahierDeTextes.all.sample.id,
                             creneau_emploi_du_temps_id: item.values[ :creneau_emploi_du_temps_id ],
                             date_cours: '2013-' + (month + 1).to_s + '-29',
                             contenu: 'Exemple de séquence pédagogique.',
                             enseignant_id: item.values[:enseignant_id] )
        STDERR.putc '.'
        Devoir.create(cours_id: cours.id,
                      type_devoir_id: TypeDevoir.all.sample.id,
                      date_due: Time.now,
                      contenu: 'Exemple de devoir.',
                      temps_estime: rand(0..120) )
        STDERR.putc '.'
      }
    }
  }
  STDERR.puts
end
