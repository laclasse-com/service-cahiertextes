# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesApp::Helpers::User do
  subject do
    Class.new { include CahierDeTextesApp::Helpers::User }
  end

  it 'Checks that the user is admin in a given etablissement when he have a TECH role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be true
  end

  it 'Checks that the user is admin in a given etablissement when he have a ADM_* role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'ADM_ETB'
                                            } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be true
  end

  it 'Checks that the user is NOT admin in a given etablissement when he have another role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'Pirate'
                                            } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be false
  end

  it 'Checks that the user is admin through profil_actif' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH'
                                            } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin? ).to be true
  end

  it 'Checks that the user is within the list of the required profile' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( GOOD ) ) ).to be true
  end

  it 'Checks that the user is within the list of required multiple profiles' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( BAD BAD2 GOOD ) ) ).to be true
  end

  it 'Checks that the user is NOT within the list of required multiple profiles' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( BAD2 BAD3 ) ) ).to be false
  end

  it 'Checks that the user is within the list of required multiple profiles or admin' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), false ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), true ) ).to be true
  end

  it 'Checks that the user is within the list of required multiple profiles or admin' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'Lambda' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], true ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), false ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), true ) ).to be false
  end

  it 'Extract the list of user\'s own regroupements\' IDs as ENS' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'classes' => [ { 'etablissement_code' => 'Test',
                                                'classe_id' => 1 },
                                              { 'etablissement_code' => 'Test',
                                                'classe_id' => 2 },
                                              { 'etablissement_code' => 'Invalid',
                                                'classe_id' => 9 } ],
                               'groupes_eleves' => [ { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 11 },
                                                     { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 99 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 12 } ],
                               'groupes_libres' => [ { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 999 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 101 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 102 } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'ENS' }
                             } }
          end
        end
      end
    end

    expect( subject.new.user_regroupements_ids ).to eq [ 1, 2, 11, 12, 101, 102 ]
  end
end
