# -*- encoding: utf-8 -*-

module Utils
  module_function

  def release_notes_to_json( version )
    return { version => 'Aucune note de version renseignée.' }.to_json if version.match( /[0-9]+\.[0-9]+/ ).nil?

    version = version.split('.').map(&:to_i)
    release_notes = YAML.load( File.read( File.expand_path( '../../../RELEASE_NOTES.yaml', __FILE__ ) ) )

    release_notes[ version[0] ][ version[1] ][ version[2] ].to_json
  end
end
