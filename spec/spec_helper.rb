# -*- coding: utf-8 -*-
require 'rubygems'

ENV['RACK_ENV'] ||= 'test'

require 'rack/test'
require 'sequel'
require 'tsort'
require 'capybara/rspec'

require_relative '../config/constants'
require_relative '../config/options'
require_relative '../config/database'

require_relative '../api'
require_relative '../web'

Capybara.default_driver = :selenium
Capybara.app = CahierDeTextesAPI::Web

module AuthenticationHelpers
  def is_logged?
    true
  end
end

module UserHelpers
  @@user = nil

  class HashIt
    def initialize( hash )
      hash.each do |k, v|
        instance_variable_set( "@#{k}", v )
        # create the getter
        self.class.send(:define_method, k, proc { instance_variable_get( "@#{k}" ) } )
        # create the setter
        # self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
      end
    end
  end

  class HashedUser < HashIt
    def is?( profil )
      # FIXME
      profils = Annuaire.get_user( @uid )['profils']
      @ENTPersonProfils.include? "#{profil}:#{profils[0]['uai']}"
    end
  end

  def user
    test_user = { 'user'                      => 'gwenhael',
                  'idEnt'                     => 'Laclasse',
                  'ENT_id'                    => '1182',
                  'uid'                       => 'VAC65103',
                  'LaclasseNom'               => 'Le Moine',
                  'LaclassePrenom'            => 'Gwenhael',
                  'LaclasseCivilite'          => 'Mr',
                  'ENTPersonStructRattachRNE' => '0699999Z',
                  'ENTStructureNomCourant'    => 'ERASME',
                  'ENTPersonProfils'          => 'DIR:0699999Z;ENS:0699999Z;ELV:0699999Z;DIR:0134567A',
                  'ENTPersonRoles'            => 'DIR_ETB:0699999Z:1' }
    @@user = HashedUser.new test_user

    @@user
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  config.include ShowMeTheCookies, type: :feature
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

  def tables_to_clean( &block )
    tsort.reverse.each( &block )
  end

  def tsort_each_node( &block )
    @db.tables.each do |t|
      block.call t unless @excluded_tables.include? t
    end
  end

  def tsort_each_child( table, &block )
    @db.foreign_key_list(table).each do |fk|
      block.call fk[:table] unless @excluded_tables.include? fk[:table]
    end
  end
end

def load_test_data
  system 'mysql -u ' + DB_CONFIG[:user] + ' -p' + DB_CONFIG[:password] + ' ' + DB_CONFIG[:name] + ' < spec/fixtures/db_dump3.sql'
end

def generate_test_data
  # STDERR.puts 'Remplissage des Cahiers de textes'
  # [ [ 'DS', 'Devoir surveillé' ],
  #   [ 'DM', 'Devoir à la maison' ],
  #   [ 'Leçon', 'Leçon à apprendre' ],
  #   [ 'Exposé', 'Exposé à préparer' ],
  #   [ 'Recherche', 'Recherche à faire' ],
  #   [ 'Exercice', 'Exercice à faire' ] ].each { |type|
  #   TypeDevoir.create(label: type[0],
  #                     description: type[1] )
  #   STDERR.putc '.'
  # }

  CahierDeTextes.all.each do |cahier_de_textes|
    12.times do
      |month|
      rand(2..4).times do
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
      end
    end
  end
  STDERR.puts
end
