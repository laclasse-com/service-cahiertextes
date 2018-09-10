# frozen_string_literal: true

mocked_annuaire_user = { 'id' => 7359,
                         'id_sconet' => nil,
                         'login' => 'gwenhael',
                         'id_jointure_aaf' => nil,
                         'nom' => 'Le Moine',
                         'prenom' => 'Gwenhael',
                         'sexe' => 'M',
                         'id_ent' => 'VAA00000',
                         'date_naissance' => '1234-05-06',
                         'adresse' => '1, rue du loin',
                         'code_postal' => '69099',
                         'ville' => 'Lyon',
                         'avatar' => '/api/avatar/user/V/A/C/283052f1f3d6ff2b_VAA00000.svg',
                         'full_name' => 'Le moine Gwenhael',
                         'profil_actif' => { 'json_class' => 'ProfilUser',
                                             'profil_id' => 'TUT',
                                             'user_id' => 7359,
                                             'etablissement_id' => 1,
                                             'bloque' => nil,
                                             'actif' => true },
                         'profils' => [{ 'profil_id' => 'TUT',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_code_uai' => '0699999Z',
                                         'profil_nom' => 'Responsable d\'un élève',
                                         'profil_code_national' => 'National_TUT',
                                         'etablissement_id' => 1,
                                         'actif' => true,
                                         'bloque' => nil },
                                       { 'profil_id' => 'DIR',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_code_uai' => '0699999Z',
                                         'profil_nom' => 'Personel de direction de l\'etablissement',
                                         'profil_code_national' => 'National_DIR',
                                         'etablissement_id' => 1,
                                         'actif' => false,
                                         'bloque' => nil },
                                       { 'profil_id' => 'DIR',
                                         'etablissement_nom' => 'Test Pronote',
                                         'etablissement_code_uai' => '0134567A',
                                         'profil_nom' => 'Personel de direction de l\'etablissement',
                                         'profil_code_national' => 'National_DIR',
                                         'etablissement_id' => 0,
                                         'actif' => false,
                                         'bloque' => nil },
                                       { 'profil_id' => 'ELV',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_code_uai' => '0699999Z',
                                         'profil_nom' => 'Elève',
                                         'profil_code_national' => 'National_ELV',
                                         'etablissement_id' => 1,
                                         'actif' => false,
                                         'bloque' => nil },
                                       { 'profil_id' => 'ENS',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_code_uai' => '0699999Z',
                                         'profil_nom' => 'Enseignant',
                                         'profil_code_national' => 'National_ENS',
                                         'etablissement_id' => 1,
                                         'actif' => false,
                                         'bloque' => nil },
                                       { 'profil_id' => 'EVS',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_code_uai' => '0699999Z',
                                         'profil_nom' => 'Personnel de vie scolaire',
                                         'profil_code_national' => 'National_EVS',
                                         'etablissement_id' => 1,
                                         'actif' => nil,
                                         'bloque' => nil }],
                         'default_password' => false,
                         'emails' => [{ 'json_class' => 'Email',
                                        'id' => 5237,
                                        'adresse' => 'test@example.com',
                                        'principal' => true,
                                        'valide' => false,
                                        'user_id' => 'VAA00000',
                                        'alias' => nil,
                                        'type' => 'Autre' }],
                         'classes' => [{ 'etablissement_code' => '0699999Z',
                                         'classe_libelle' => 'MS5',
                                         'etablissement_nom' => 'ERASME',
                                         'matiere_enseignee_id' => '003700',
                                         'matiere_libelle' => 'AIDE ET ACCOMPAGNEMENT TRAVAIL PERSONNEL',
                                         'classe_id' => 578,
                                         'etablissement_id' => 1,
                                         'prof_principal' => 'N' },
                                       { 'etablissement_code' => '0699999Z',
                                         'classe_libelle' => '2emeclas',
                                         'etablissement_nom' => 'ERASME',
                                         'matiere_enseignee_id' => '001300',
                                         'matiere_libelle' => 'PRATIQUES PROFESSIONNELLES',
                                         'classe_id' => 579,
                                         'etablissement_id' => 1,
                                         'prof_principal' => 'N' },
                                       { 'etablissement_code' => '0699999Z',
                                         'classe_libelle' => '2emeclas',
                                         'etablissement_nom' => 'ERASME',
                                         'matiere_enseignee_id' => '003700',
                                         'matiere_libelle' => 'AIDE ET ACCOMPAGNEMENT TRAVAIL PERSONNEL',
                                         'classe_id' => 579,
                                         'etablissement_id' => 1,
                                         'prof_principal' => 'N' },
                                       { 'etablissement_code' => '0699999Z',
                                         'classe_id' => 578,
                                         'classe_libelle' => 'MS5',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_id' => 1 },
                                       { 'etablissement_code' => '0699999Z',
                                         'classe_id' => 579,
                                         'classe_libelle' => '2emeclas',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_id' => 1 },
                                       { 'etablissement_code' => '0699999Z',
                                         'classe_id' => 580,
                                         'classe_libelle' => '5° C',
                                         'etablissement_nom' => 'ERASME',
                                         'etablissement_id' => 1 }],
                         'telephones' => [],
                         'groupes_eleves' => [],
                         'groupes_libres' => [],
                         'parents' => [],
                         'enfants' => [{ 'enfant' => { 'id_ent' => 'VAA00000' } }],
                         'relations_eleves' => [],
                         'relations_adultes' => [] }

MOCKED_DATA = {
    users: {
        eleve: { rack_session: { 'user'                      => 'gwenhael',
                                 'idEnt'                     => 'Laclasse',
                                 'ENT_id'                    => '0000',
                                 'uid'                       => 'VAA00000',
                                 'nom'               => 'Le Moine',
                                 'prenom'            => 'Gwenhael',
                                 'LaclasseCivilite'          => 'Mr',
                                 'ENTPersonStructRattachRNE' => '0699990Z',
                                 'ENTStructureNomCourant'    => 'ERASME',
                                 'ENTPersonProfils'          => 'ELV:0699990Z',
                                 'ENTPersonRoles'            => 'ELV:0699990Z:1' },
                 annuaire: mocked_annuaire_user },
        enseignant: { rack_session: { 'user' => 'gwenhael',
                                      'idEnt'                     => 'Laclasse',
                                      'ENT_id'                    => '0000',
                                      'uid'                       => 'VAA00000',
                                      'nom'               => 'Le Moine',
                                      'prenom'            => 'Gwenhael',
                                      'LaclasseCivilite'          => 'Mr',
                                      'ENTPersonStructRattachRNE' => '0699990Z',
                                      'ENTStructureNomCourant'    => 'ERASME',
                                      'ENTPersonProfils'          => 'ENS:0699990Z',
                                      'ENTPersonRoles'            => 'ENS:0699990Z:1' },
                      annuaire: mocked_annuaire_user },
        principal: { rack_session: { 'user' => 'gwenhael',
                                     'idEnt'                     => 'Laclasse',
                                     'ENT_id'                    => '0000',
                                     'uid'                       => 'VAA00000',
                                     'nom'               => 'Le Moine',
                                     'prenom'            => 'Gwenhael',
                                     'LaclasseCivilite'          => 'Mr',
                                     'ENTPersonStructRattachRNE' => '0699990Z',
                                     'ENTStructureNomCourant'    => 'ERASME',
                                     'ENTPersonProfils'          => 'DIR:0699990Z;DIR:0134567A',
                                     'ENTPersonRoles'            => 'DIR_ETB:0699990Z:1' },
                     annuaire: mocked_annuaire_user },
        vie_scolaire: { rack_session: { 'user' => 'gwenhael',
                                        'idEnt'                     => 'Laclasse',
                                        'ENT_id'                    => '0000',
                                        'uid'                       => 'VAA00000',
                                        'nom'               => 'Le Moine',
                                        'prenom'            => 'Gwenhael',
                                        'LaclasseCivilite'          => 'Mr',
                                        'ENTPersonStructRattachRNE' => '0699990Z',
                                        'ENTStructureNomCourant'    => 'ERASME',
                                        'ENTPersonProfils'          => 'EVS:0699990Z',
                                        'ENTPersonRoles'            => 'EVS:0699990Z:1' },
                        annuaire: mocked_annuaire_user },
        parent: { rack_session: { 'user' => 'gwenhael',
                                  'idEnt'                     => 'Laclasse',
                                  'ENT_id'                    => '0000',
                                  'uid'                       => 'VAA00000',
                                  'nom'               => 'Le Moine',
                                  'prenom'            => 'Gwenhael',
                                  'LaclasseCivilite'          => 'Mr',
                                  'ENTPersonStructRattachRNE' => '0699990Z',
                                  'ENTStructureNomCourant'    => 'ERASME',
                                  'ENTPersonProfils'          => 'TUT:0699990Z',
                                  'ENTPersonRoles'            => 'TUT:0699990Z:1' },
                  annuaire: mocked_annuaire_user }
    },

    etablissement: { 'id' => 1,
                     'code_uai' => '0699999Z',
                     'nom' => 'ERASME',
                     'adresse' => nil,
                     'code_postal' => nil,
                     'ville' => nil,
                     'type_etablissement_id' => 1,
                     'telephone' => nil,
                     'fax' => nil,
                     'full_name' => 'Service du département ERASME',
                     'alimentation_state' => 'Non alimenté',
                     'alimentation_date' => nil,
                     'data_received' => false,
                     'longitude' => nil,
                     'latitude' => nil,
                     'site_url' => nil,
                     'logo' => nil,
                     'classes' =>
                   [{ 'id' => 578,
                      'libelle' => 'Moyenne Section 5',
                      'description' => nil,
                      'date_last_maj_aaf' => nil,
                      'libelle_aaf' => 'MS5',
                      'type_regroupement_id' => 'CLS',
                      'code_mef_aaf' => '00010001320',
                      'etablissement_id' => 1,
                      'ctime' => '2014-09-15 10:01:32 +0200',
                      'url_blog' => nil,
                      'regroupement_id' => 578,
                      'profs' => 1,
                      'eleves' => 1,
                      'ent_mef_jointure' => '00010001320',
                      'mef_libelle' => 'MOYENNE SECTION',
                      'ent_mef_rattach' => '00010001320',
                      'ent_mef_stat' => '11120010001' },
                    { 'id' => 579,
                      'libelle' => '2c',
                      'description' => nil,
                      'date_last_maj_aaf' => nil,
                      'libelle_aaf' => '2emeclas',
                      'type_regroupement_id' => 'CLS',
                      'code_mef_aaf' => '00210002220',
                      'etablissement_id' => 1,
                      'ctime' => '2014-09-18 15:33:59 +0200',
                      'url_blog' => nil,
                      'regroupement_id' => nil,
                      'profs' => 2,
                      'eleves' => nil,
                      'ent_mef_jointure' => '00210002220',
                      'mef_libelle' => 'CE2',
                      'ent_mef_rattach' => '00210002220',
                      'ent_mef_stat' => '11230010002' },
                    { 'id' => 580,
                      'libelle' => 'cinquieme',
                      'description' => nil,
                      'date_last_maj_aaf' => nil,
                      'libelle_aaf' => '5° C',
                      'type_regroupement_id' => 'CLS',
                      'code_mef_aaf' => '10110001117',
                      'etablissement_id' => 1,
                      'ctime' => '2014-10-07 12:15:41 +0200',
                      'url_blog' => nil,
                      'regroupement_id' => 580,
                      'profs' => nil,
                      'eleves' => 1,
                      'ent_mef_jointure' => '10110001117',
                      'mef_libelle' => '5EME SECTION SPORTIVE',
                      'ent_mef_rattach' => '10110001110',
                      'ent_mef_stat' => '21120010001' }],
                     'groupes_eleves' => [],
                     'groupes_libres' =>
                   [{ 'id' => 1,
                      'created_at' => '2014-09-16',
                      'nom' => 'QUENIN',
                      'prenom' => 'Hadrien',
                      'id_ent' => 'VAC65101',
                      'libelle' => 'v',
                      'membres' => 1 },
                    { 'id' => 2,
                      'created_at' => '2014-09-16',
                      'nom' => 'QUENIN',
                      'prenom' => 'Hadrien',
                      'id_ent' => 'VAC65101',
                      'libelle' => 'GRP1',
                      'membres' => nil }],
                     'personnel' =>
                   [{ 'id' => 1,
                      'id_ent' => 'VAA60000',
                      'nom' => 'Admin',
                      'prenom' => 'istrateur',
                      'profil_id' => 'COL',
                      'description' => nil,
                      'etablissement_id' => 1,
                      'code_national' => 'National_COL',
                      'libelle' => nil,
                      'roles' =>
                       [{ 'role_id' => 'ADM_ETB', 'libelle' => 'Administrateur d\'établissement' },
                        { 'role_id' => 'PROF_ETB', 'libelle' => 'Professeur' },
                        { 'role_id' => 'TECH', 'libelle' => 'Administrateur technique' }] },
                    { 'id' => 7359,
                      'id_ent' => 'VAC65103',
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'profil_id' => 'ENS',
                      'description' => nil,
                      'etablissement_id' => 1,
                      'code_national' => 'National_ENS',
                      'libelle' => nil,
                      'roles' =>
                      [{ 'role_id' => 'ELV_ETB', 'libelle' => 'Elève' },
                       { 'role_id' => 'PAR_ETB', 'libelle' => 'Parent' },
                       { 'role_id' => 'PROF_ETB', 'libelle' => 'Professeur' },
                       { 'role_id' => 'TECH', 'libelle' => 'Administrateur technique' },
                       { 'role_id' => 'ADM_ETB', 'libelle' => 'Administrateur d\'établissement' },
                       { 'role_id' => 'AVS_ETB', 'libelle' => 'Assistance vie scolaire' }] }],
                     'contacts' =>
                   [{ 'id_ent' => 'VAA60000',
                      'nom' => 'Admin',
                      'prenom' => 'istrateur',
                      'description' => 'Administrateur d\'établissement',
                      'profil_id' => 'ADM_ETB' },
                    { 'id_ent' => 'VAC65103',
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'description' => 'Administrateur d\'établissement',
                      'profil_id' => 'ADM_ETB' },
                    { 'id_ent' => 'VAA60000',
                      'nom' => 'Admin',
                      'prenom' => 'istrateur',
                      'description' => 'Administrateur technique', 'profil_id' => 'TECH' },
                    { 'id_ent' => 'VAC65101',
                      'nom' => 'QUENIN',
                      'prenom' => 'Hadrien',
                      'description' => 'Administrateur technique',
                      'profil_id' => 'TECH' },
                    { 'id_ent' => 'VAC65103',
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'description' => 'Administrateur technique',
                      'profil_id' => 'TECH' }],
                     'eleves' =>
                   [{ 'profil_id' => 'ELV',
                      'user_id' => 7359,
                      'etablissement_id' => 1,
                      'id_sconet' => nil,
                      'id_jointure_aaf' => nil,
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'id_ent' => 'VAC65103' },
                    { 'profil_id' => 'ELV',
                      'user_id' => 7363,
                      'etablissement_id' => 1,
                      'id_sconet' => nil,
                      'id_jointure_aaf' => nil,
                      'nom' => 'eleve',
                      'prenom' => 'eleve',
                      'id_ent' => 'VAC65109' }],
                     'enseignants' =>
                   [{ 'profil_id' => 'ENS',
                      'user_id' => 7359,
                      'etablissement_id' => 1,
                      'id_sconet' => nil,
                      'id_jointure_aaf' => nil,
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'id_ent' => 'VAC65103' }],
                     'parents' =>
                   [{ 'profil_id' => 'TUT',
                      'user_id' => 7359,
                      'etablissement_id' => 1,
                      'id_sconet' => nil,
                      'id_jointure_aaf' => nil,
                      'nom' => 'Le%20Moine',
                      'prenom' => 'Gwenhael',
                      'id_ent' => 'VAC65103' }] }
}.freeze
