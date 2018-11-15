# frozen_string_literal: true

MOCK_UAI = '0699999Z'
MOCK_UID = 'VZZ6999'

MOCK_DATE = DateTime.now
MOCK_ASSIGNMENT_TYPE_ID = AssignmentType.first.id
MOCK_CONTENT = "test"

MOCK_HASH = 'hash'
MOCK_KNOWN_ID = 'known_id'

MOCK_WEEKDAY = Time.now.wday
MOCK_START_TIME = Time.now.strftime( "2000-01-01T%H:00:00+01:00" )
MOCK_END_TIME = Time.now.strftime( "2000-01-01T%H:30:00+01:00" )
MOCK_GROUP_ID = 999_999
MOCK_GROUP_ID2 = 111_111
MOCK_SUBJECT_ID = "SUBJECT_ID"

MOCK_LABEL = 'label'
MOCK_NAME = 'name'

MOCK_USER_GENERIC = {
    'id' => "#{MOCK_UID}A",
    'profiles' => [ { 'type' => 'TECH' },
                    { 'type' => 'ADM',
                      'structure_id' => MOCK_UAI },
                    { 'type' => 'DIR',
                      'structure_id' => MOCK_UAI } ],
    'groups' => [ { 'type' => 'ELV',
                    'group_id' => MOCK_GROUP_ID },
                  { 'type' => 'ENS',
                    'group_id' => MOCK_GROUP_ID,
                    'subject_id' => MOCK_SUBJECT_ID },
                  { 'type' => 'ENS',
                    'group_id' => MOCK_GROUP_ID2,
                    'subject_id' => MOCK_SUBJECT_ID } ]
}.freeze

MOCK_USER_ENS = {
    'id' => "#{MOCK_UID}9",
    'profiles' => [ { 'type' => 'ENS',
                      'structure_id' => MOCK_UAI } ],
    'groups' => [ { 'type' => 'ENS',
                    'group_id' => MOCK_GROUP_ID,
                    'subject_id' => MOCK_SUBJECT_ID },
                  { 'type' => 'ENS',
                    'group_id' => MOCK_GROUP_ID2,
                    'subject_id' => MOCK_SUBJECT_ID } ]
}.freeze

MOCK_USER_ELV = {
    'id' => "#{MOCK_UID}0",
    'profiles' => [ { 'type' => 'ELV',
                      'structure_id' => MOCK_UAI } ],
    'groups' => [ { 'type' => 'ELV',
                    'group_id' => MOCK_GROUP_ID } ]
}.freeze

MOCK_USER_ADM = {
    'id' => "#{MOCK_UID}1",
    'profiles' => [ { 'type' => 'ADM',
                      'structure_id' => MOCK_UAI } ]
}.freeze

MOCK_USER_ADM_PRONOTE = {
    'id' => "#{MOCK_UID}1",
    'profiles' => [ { 'type' => 'ADM',
                      'structure_id' => '0134567U' } ]
}.freeze

MOCK_USER_DIR = {
    'id' => "#{MOCK_UID}2",
    'profiles' => [ { 'type' => 'DIR',
                      'structure_id' => MOCK_UAI } ]
}.freeze

$mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

module LaClasse
    module Helpers
        module Auth
            module_function

            def session
                { 'user' => MOCK_UID }
            end

            def logged?
                true            # Yeah yeah you are logged *wink*
            end

            def login!
                nop
            end
        end
    end
end

module LaClasse
    module Helpers
        module User
            module_function

            def user( _uid = nil )
                $mock_user  # rubocop:disable Style/GlobalVars
            end
        end
    end
end
