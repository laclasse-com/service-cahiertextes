# frozen_string_literal: true

MOCK_UAI = '0699999Z'

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

module LaClasse
    module Helpers
        module Auth
            module_function

            def session
                { 'user' => 'VZZ69999' }
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
                {
                    'id' => "VZZ69999",
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
                }
            end
        end
    end
end
