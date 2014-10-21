# encoding: utf-8

require_relative '../../lib/HashedUser'

module UserHelpers
  def user
    HashedUser.new( { 'user'                      => 'gwenhael',
                      'idEnt'                     => 'Laclasse',
                      'ENT_id'                    => '1182',
                      'uid'                       => 'VAC65103',
                      'LaclasseNom'               => 'Le Moine',
                      'LaclassePrenom'            => 'Gwenhael',
                      'LaclasseCivilite'          => 'Mr',
                      'ENTPersonStructRattachRNE' => '0699999Z',
                      'ENTStructureNomCourant'    => 'ERASME',
                      'ENTPersonProfils'          => 'DIR:0699999Z;ENS:0699999Z;ELV:0699999Z;DIR:0134567A',
                      'ENTPersonRoles'            => 'DIR_ETB:0699999Z:1' } )
  end
end
