'use strict';
angular.module('cahierDeTextesClientApp', ['angularMoment',
    'chieffancypants.loadingBar',
    'ngAnimate',
    'ngColorPicker',
    'ngLocale',
    'ngResource',
    'ngSanitize',
    'ngTouch',
    'nvd3',
    'textAngular',
    'uiSwitch',
    'toastr',
    'ui.bootstrap',
    'ui.bootstrap.dropdown',
    'ui.calendar',
    'ui.checkbox',
    'ui.router',
    'ui.select']);
angular.module('cahierDeTextesClientApp')
    .config(['$httpProvider',
    function ($httpProvider) {
        $httpProvider.defaults.withCredentials = true;
    }])
    .config(['cfpLoadingBarProvider',
    function (cfpLoadingBarProvider) {
        cfpLoadingBarProvider.latencyThreshold = 500;
    }])
    .run(['amMoment',
    function (amMoment) {
        amMoment.changeLocale('fr');
    }])
    .constant('angularMomentConfig', { timezone: 'Europe/Brussels' })
    .config(['$provide',
    function ($provide) {
        $provide.decorator('taTranslations', ['$delegate',
            function ($delegate) {
                $delegate.html.tooltip = 'Basculer entre les vues HTML et texte enrichi';
                $delegate.justifyLeft.tooltip = 'Justifier à gauche';
                $delegate.justifyCenter.tooltip = 'Centrer';
                $delegate.justifyRight.tooltip = 'Justifier à droite';
                $delegate.bold.tooltip = 'Mettre en gras';
                $delegate.italic.tooltip = 'Mettre en italique';
                $delegate.underline.tooltip = 'Souligner';
                $delegate.insertLink.tooltip = 'Insérer un lien';
                $delegate.insertLink.dialogPrompt = 'Lien à insérer';
                $delegate.editLink.targetToggle.buttontext = 'Le lien s\'ouvrira dans une nouvelle fenêtre';
                $delegate.editLink.reLinkButton.tooltip = 'Éditer le lien';
                $delegate.editLink.unLinkButton.tooltip = 'Enlever le lien';
                $delegate.insertImage.tooltip = 'Insérer une image';
                $delegate.insertImage.dialogPrompt = 'URL de l\'image :';
                $delegate.insertVideo.tooltip = 'Insérer une vidéo';
                $delegate.insertVideo.dialogPrompt = 'URL de la vidéo Youtube :';
                $delegate.clear.tooltip = 'Enlever le formattage';
                $delegate.ul.tooltip = 'Liste';
                $delegate.ol.tooltip = 'Liste numérotée';
                $delegate.quote.tooltip = 'Citation';
                $delegate.undo.tooltip = 'Annuler';
                $delegate.redo.tooltip = 'Rétablir';
                return $delegate;
            }]);
        $provide.decorator('taOptions', ['$delegate', 'taRegisterTool',
            function (taOptions, taRegisterTool) {
                taOptions.toolbar = [
                    ['bold', 'italics', 'underline', 'ul', 'ol', 'quote', 'justifyLeft', 'justifyCenter', 'justifyRight', 'insertLink', 'insertImage', 'insertVideo', 'html', 'redo', 'undo']
                ];
                var colorpicker_taTool = function (type) {
                    var style = (type === 'backcolor') ? 'background-' : '';
                    var couleurs = ['#7bd148', '#5484ed', '#a4bdfc', '#46d6db', '#7ae7bf', '#51b749', '#fbd75b', '#ffb878', '#ff887c', '#dc2127', '#dbadff', '#e1e1e1'];
                    if (type === 'backcolor') {
                        couleurs.push('transparent');
                    }
                    return {
                        couleurs: couleurs,
                        display: "<span uib-dropdown><a uib-dropdown-toggle><i class=\"fa fa-font\" data-ng-style=\"{'" + style + "color': selected }\"></i> <i class=\"fa fa-caret-down\"></i></a><ng-color-picker uib-dropdown-menu selected=\"selected\" colors=\"couleurs\"></ng-color-picker></span>",
                        action: function () {
                            return (this.selected === 'nil') ? false : this.$editor().wrapSelection(type, this.selected);
                        }
                    };
                };
                taRegisterTool('fontColor', colorpicker_taTool('forecolor'));
                taOptions.toolbar[0].push('fontColor');
                taRegisterTool('backgroundColor', colorpicker_taTool('backcolor'));
                taOptions.toolbar[0].push('backgroundColor');
                taRegisterTool('table', {
                    columns: {
                        value: 1,
                        hovered: 1
                    },
                    rows: {
                        value: 1,
                        hovered: 1
                    },
                    hover: function (objet, value) {
                        objet.hovered = value;
                    },
                    leave: function (objet) {
                        objet.hovered = objet.value;
                    },
                    tooltiptext: 'insérer un tableau',
                    display: '<span uib-dropdown><a uib-dropdown-toggle><i class="fa fa-table"></i> <i class="fa fa-caret-down"></i></a><div uib-dropdown-menu data-ng-click="$event.stopPropagation()"><label><span uib-rating on-hover="hover( columns, value )" on-leave="leave( columns )" ng-model="columns.value" max="15" state-on="\'glyphicon-stop\'" state-off="\'glyphicon-unchecked\'"></span><br>{{columns.hovered}} colonnes</label><br><label><span uib-rating on-hover="hover( rows, value )" on-leave="leave( rows )" ng-model="rows.value" max="15" state-on="\'glyphicon-stop\'" state-off="\'glyphicon-unchecked\'"></span><br>{{rows.hovered}} lignes</label><br><button class="btn btn-success" data-ng-click="insert_table()">Insérer</button></div></span>',
                    insert_table: function () {
                        var tds = '';
                        for (var idxCol = 0; idxCol < this.columns.value; idxCol++) {
                            tds = tds + "<td>&nbsp;</td>";
                        }
                        var trs = '';
                        for (var idxRow = 0; idxRow < this.rows.value; idxRow++) {
                            trs = trs + "<tr>" + tds + "</tr>";
                        }
                        this.$editor().wrapSelection('insertHTML', "<table class=\"table table-bordered\">" + trs + "</table>");
                        this.deferration.resolve();
                    },
                    action: function (deferred) {
                        this.deferration = deferred;
                        return false;
                    }
                });
                taOptions.toolbar[0].push('table');
                taOptions.classes = {
                    focussed: 'focussed',
                    toolbar: 'btn-toolbar',
                    toolbarGroup: 'btn-group',
                    toolbarButton: 'btn btn-default',
                    toolbarButtonActive: 'active',
                    disabled: 'disabled',
                    textEditor: 'form-control',
                    htmlEditor: 'form-control'
                };
                return taOptions;
            }]);
        $provide.decorator('taTools', ['$delegate',
            function (taTools) {
                taTools.html.buttontext = 'HTML';
                return taTools;
            }]);
    }])
    .config(['toastrConfig',
    function (toastrConfig) {
        angular.extend(toastrConfig, {
            allowHtml: true,
            closeButton: false,
            closeHtml: '<button>&times;</button>',
            containerId: 'toast-container',
            extendedTimeOut: 1000,
            iconClasses: {
                error: 'toast-error',
                info: 'toast-info',
                success: 'toast-success',
                warning: 'toast-warning'
            },
            maxOpened: 0,
            messageClass: 'toast-message',
            newestOnTop: true,
            onHidden: null,
            onShown: null,
            positionClass: 'toast-bottom-right',
            tapToDismiss: true,
            target: 'body',
            timeOut: 5000,
            titleClass: 'toast-title',
            toastClass: 'toast'
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .constant('LOCALHOST', false)
    .constant('ZONE', 'A')
    .constant('POPUP_ACTIONS', {
    CANCELLED: 'CANCELLED',
    CRENEAU_DELETED: 'CRENEAU_DELETED',
    CRENEAU_MODIFIED: 'CRENEAU_MODIFIED',
    SEQUENCE_PEDAGOGIQUE_CREATED: 'SEQUENCE_PEDAGOGIQUE_CREATED',
    SEQUENCE_PEDAGOGIQUE_MODIFIED: 'SEQUENCE_PEDAGOGIQUE_MODIFIED',
    SEQUENCE_PEDAGOGIQUE_DUPLICATED: 'SEQUENCE_PEDAGOGIQUE_DUPLICATED',
    SEQUENCE_PEDAGOGIQUE_DELETED: 'SEQUENCE_PEDAGOGIQUE_DELETED',
    DEVOIR_CREATED: 'DEVOIR_CREATED',
    DEVOIR_MODIFIED: 'DEVOIR_MODIFIED',
    DEVOIR_DUPLICATED: 'DEVOIR_DUPLICATED',
    DEVOIR_DELETED: 'DEVOIR_DELETED'
})
    .constant('MULTIBARCHART_DEFINITION', {
    data: [],
    options: {
        chart: {
            type: 'multiBarChart',
            height: 240,
            showControls: false,
            showLegend: true,
            showLabels: true,
            stacked: false,
            duration: 500,
            reduceXTicks: false,
            rotateLabels: -45,
            labelSunbeamLayout: true,
            color: function (d, i) {
                var colors = {
                    'saisies non visées': '#aaffaa',
                    'saisies visées': '#00ff00'
                };
                return colors[d.key];
            }
        }
    }
})
    .constant('PIECHART_DEFINITION', {
    data: [{ label: 'saisie', value: 0 },
        { label: 'valide', value: 0 }],
    options: {
        chart: {
            type: 'pieChart',
            height: 128,
            x: function (d) { return d.label; },
            y: function (d) { return d.value; },
            color: function (d, i) {
                var colors = {
                    'saisies non visées': '#aaffaa',
                    'saisies visées': '#00ff00'
                };
                return colors[d.label];
            },
            showLabels: false,
            showLegend: true,
            duration: 500,
            labelThreshold: 0.01,
            labelSunbeamLayout: true
        }
    }
});
angular.module('cahierDeTextesClientApp')
    .config(['$httpProvider',
    function ($httpProvider) {
        $httpProvider.interceptors.push(['$q',
            function ($q) {
                return {
                    'response': function (response) {
                        return response;
                    },
                    'responseError': function (rejection) {
                        if (rejection.status === 401) {
                            swal({
                                title: 'Erreur',
                                text: 'Votre session a expirée.',
                                type: 'error',
                                showCancelButton: false,
                                confirmButtonColor: '#ff6b55',
                                confirmButtonText: 'Fermer',
                                timer: 3000
                            });
                        }
                        return $q.reject(rejection);
                    }
                };
            }]);
    }]);
angular.module('cahierDeTextesClientApp')
    .config(['$stateProvider', '$urlRouterProvider', 'APP_PATH',
    function ($stateProvider, $urlRouterProvider, APP_PATH) {
        $urlRouterProvider.otherwise('/');
        $stateProvider
            .state('404', {
            url: '404',
            templateUrl: APP_PATH + "/app/views/404.html"
        })
            .state('index', {
            url: '/',
            templateUrl: APP_PATH + "/app/views/index.html",
            controller: 'IndexCtrl',
            resolve: {
                auth: ['Redirection', function (Redirection) { Redirection.doorman(['ADM', 'DIR', 'ENS', 'DOC', 'ELV', 'TUT', 'EVS']); }],
                current_user: ['CurrentUser', function (CurrentUser) { return CurrentUser.get().then(function (response) { return response.data; }); }]
            }
        })
            .state('emploi_du_temps', {
            parent: 'index',
            url: 'emploi_du_temps',
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/textbook.html",
                    controller: 'TextBookCtrl'
                }
            }
        })
            .state('devoirs', {
            parent: 'index',
            url: 'devoirs',
            resolve: { auth: ['Redirection', function (Redirection) { Redirection.doorman(['ELV', 'TUT']); }] },
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/assignements.html",
                    controller: 'AssignementsCtrl'
                }
            }
        })
            .state('import', {
            parent: 'index',
            url: 'import',
            resolve: { auth: ['Redirection', function (Redirection) { Redirection.doorman(['DIR', 'ADM']); }] },
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/import.html",
                    controller: 'ImportCtrl'
                }
            }
        })
            .state('enseignants', {
            parent: 'index',
            url: 'enseignants',
            resolve: { auth: ['Redirection', function (Redirection) { Redirection.doorman(['DIR']); }] },
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/dashboard_teachers.html",
                    controller: 'DashboardTeachersCtrl'
                }
            }
        })
            .state('enseignant', {
            parent: 'index',
            url: 'enseignants/:enseignant_id',
            resolve: { auth: ['Redirection', function (Redirection) { Redirection.doorman(['DIR']); }] },
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/dashboard_teacher.html",
                    controller: 'DashboardTeacherCtrl'
                }
            }
        })
            .state('stats', {
            parent: 'index',
            url: 'stats',
            resolve: { auth: ['Redirection', function (Redirection) { Redirection.doorman(['ENS', 'DOC']); }] },
            views: {
                'content': {
                    templateUrl: APP_PATH + "/app/views/dashboard_teacher.html",
                    controller: 'DashboardTeacherCtrl'
                }
            }
        });
    }])
    .run(['$rootScope', 'log',
    function ($rootScope, log) {
        $rootScope.$on('$stateChangeSuccess', function (event, toState, toParams, fromState, fromParams) {
            log.add('CTXT', null, null);
        });
    }
]);
angular.module('cahierDeTextesClientApp')
    .component('displayDevoir', {
    bindings: { devoir: '=' },
    template: '<div ng:class="{ \'type1\': $ctrl.devoir.type_devoir_id === 1,' +
        ' \'type2\': $ctrl.devoir.type_devoir_id === 2,' +
        ' \'type3\': $ctrl.devoir.type_devoir_id === 3,' +
        ' \'type4\': $ctrl.devoir.type_devoir_id === 4,' +
        ' \'type5\': $ctrl.devoir.type_devoir_id === 5,' +
        ' \'type6\': $ctrl.devoir.type_devoir_id === 6,' +
        ' \'fait\': $ctrl.devoir.fait,' +
        ' \'a-faire\': !$ctrl.devoir.fait }">' +
        '    <h5><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_matiere.svg)\'}"></i> {{$ctrl.devoir.matiere.name}} </h5>' +
        '    <h6><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_devoir.svg)\'}"></i> {{$ctrl.devoir.type_devoir.description}} : </h6>' +
        '    <span ng:if="$ctrl.display_time_estimation && $ctrl.devoir.temps_estime > 0"><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_temps.svg)\'}"></i> Temps estimé : <em>{{$ctrl.devoir.temps_estime * 5}} minutes</em></span>' +
        '    <div class="alert alert-default" ng:bind-html="$ctrl.devoir.contenu"></div>' +
        '    <div class="row col-md-12 ressources">' +
        '      <div class="attached-document" ng:repeat="ressource in $ctrl.devoir.ressources">' +
        '        <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
        '      </div>' +
        '    </div>' +
        '</div>',
    controller: ['$sce', 'URL_DOCS', 'APP_PATH', 'API',
        function ($sce, URL_DOCS, APP_PATH, API) {
            var ctrl = this;
            ctrl.$onInit = function () {
                ctrl.app_path = APP_PATH;
                ctrl.display_time_estimation = false;
                ctrl.devoir.contenu = $sce.trustAsHtml(ctrl.devoir.contenu);
                API.get_type_de_devoir(ctrl.devoir.type_devoir_id)
                    .then(function (response) {
                    ctrl.devoir.type_devoir = response.data;
                });
                _(ctrl.devoir.ressources).each(function (ressource) {
                    ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                });
            };
        }]
});
angular.module('cahierDeTextesClientApp')
    .component('displaySequencePedagogique', {
    bindings: { sp: '<' },
    template: '<h5>Séquence pédagogique du {{$ctrl.sp.date_cours | amDateFormat:\'dddd D MMMM\'}}</h5>' +
        '<div class="alert alert-default" ng:bind-html="$ctrl.sp.contenu"></div>' +
        '<ul ng:if="sp.ressources.length > 0">' +
        '  <li ng:repeat="ressource in sp.ressources">' +
        '    <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
        '  </li>' +
        '</ul>',
    controller: ['$sce', 'URL_DOCS',
        function ($sce, URL_DOCS) {
            var ctrl = this;
            ctrl.$onInit = function () {
                if (typeof ctrl.sp.contenu == String) {
                    ctrl.sp.contenu = $sce.trustAsHtml(ctrl.sp.contenu);
                }
                _(ctrl.sp.ressources).each(function (ressource) {
                    ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                });
            };
        }]
});
angular.module('cahierDeTextesClientApp')
    .component('switchDevoir', {
    bindings: { devoir: '=' },
    template: '<span switch' +
        '      class="violet"' +
        '      ng:if="!($ctrl.devoir.type_devoir_id == 1)"' +
        '      ng:model="$ctrl.devoir.fait"' +
        '      ng:change="$ctrl.fait( $ctrl.devoir )" ></span>',
    controller: ['toastr',
        function (toastr) {
            var ctrl = this;
            ctrl.fait = function (devoir) {
                devoir.$fait()
                    .then(function (response) {
                    if (response.fait) {
                        toastr.success('Devoir fait.', 'Bravo !');
                    }
                    else {
                        toastr.info('Devoir à faire', 'Encore un pett effort.');
                    }
                });
            };
        }]
});
angular.module('cahierDeTextesClientApp')
    .controller('AssignementsCtrl', ['$scope', '$sce', '$timeout', 'toastr', '$state', 'moment',
    'APP_PATH', 'URL_DOCS', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauxEmploiDuTemps', 'CurrentUser',
    function ($scope, $sce, $timeout, toastr, $state, moment, APP_PATH, URL_DOCS, API, Annuaire, Devoirs, Cours, CreneauxEmploiDuTemps, CurrentUser) {
        var ctrl = $scope;
        ctrl.affiche_faits = false;
        ctrl.tri_ascendant = true;
        ctrl.popup_ouverte = false;
        ctrl.matiere_selected = null;
        var getCours = _.memoize(function (id) {
            return Cours.get({ id: id });
        });
        var getCreneauxEmploiDuTemps = _.memoize(function (id) {
            return CreneauxEmploiDuTemps.get({ id: id });
        });
        ctrl.filter_data = function (matiere) {
            if (_(matiere).isNull()) {
                ctrl.devoirs = ctrl.all_devoirs;
            }
            else {
                ctrl.devoirs = _(ctrl.all_devoirs).select(function (devoir) {
                    return devoir.creneau_emploi_du_temps.matiere_id == matiere.id;
                });
            }
        };
        ctrl.period_offset = 0;
        var nb_mois_depuis_septembre = Math.abs(9 - (moment().month() + 1));
        ctrl.period_offsets_list = _.range(nb_mois_depuis_septembre, (10 - nb_mois_depuis_septembre) * -1, -1)
            .map(function (offset) {
            return {
                offset: offset,
                label: offset == 0 ? 'ce mois' : moment().add(offset * -1, 'months').fromNow()
            };
        });
        ctrl.incr_offset = function () { ctrl.period_offset++; };
        ctrl.decr_offset = function () { ctrl.period_offset--; };
        ctrl.reset_offset = function () { ctrl.period_offset = 0; };
        CurrentUser.get()
            .then(function (response) {
            ctrl.current_user = response.data;
            var retrieve_data = function () {
                ctrl.from_date = moment().subtract(ctrl.period_offset, 'months').subtract(2, 'weeks').toDate();
                ctrl.to_date = moment().subtract(ctrl.period_offset, 'months').add(2, 'weeks').toDate();
                API.query_devoirs({
                    'date_due>': ctrl.from_date,
                    'date_due<': ctrl.to_date,
                    'groups_ids[]': ctrl.current_user.profil_actif.type === 'TUT' ? _(ctrl.current_user.enfant_actif.enfant.groups).pluck('group_id') : _(ctrl.current_user.groups).pluck('group_id'),
                    'uid': ctrl.current_user.profil_actif.type === 'TUT' ? ctrl.current_user.enfant_actif.child_id : ctrl.current_user.id,
                    'check_done': ctrl.current_user.profil_actif.type === 'ELV'
                })
                    .$promise.then(function (response) {
                    ctrl.matieres = {};
                    ctrl.all_devoirs = _(response).map(function (devoir) {
                        devoir.cours = getCours(devoir.cours_id);
                        devoir.creneau_emploi_du_temps = getCreneauxEmploiDuTemps(devoir.creneau_emploi_du_temps_id);
                        devoir.creneau_emploi_du_temps.$promise
                            .then(function () {
                            Annuaire.get_subject(devoir.creneau_emploi_du_temps.matiere_id)
                                .then(function (response) {
                                devoir.matiere = response.data;
                                ctrl.matieres[devoir.matiere.id] = devoir.matiere;
                            });
                        });
                        _(devoir.ressources).each(function (ressource) {
                            ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                        });
                        return devoir;
                    });
                    ctrl.filter_data(ctrl.matiere_selected);
                });
            };
            ctrl.$watch('period_offset', function () {
                retrieve_data();
            });
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('DashboardTeacherCtrl', ['$scope', '$stateParams', '$q', '$locale', '$timeout', 'moment', 'toastr',
    'API', 'Cours', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
    function ($scope, $stateParams, $q, $locale, $timeout, moment, toastr, API, Cours, Annuaire, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION) {
        $scope.mois = _($locale.DATETIME_FORMATS.MONTH).toArray();
        $scope.scope = $scope;
        $scope.moisCourant = null;
        $scope.montre_valides = current_user.profil_actif.type !== 'DIR';
        $scope.nb_saisies_visables = 0;
        $scope.current_user = current_user;
        $scope.enseignant_id = _($stateParams).has('enseignant_id') ? $stateParams.enseignant_id : $scope.current_user.id;
        var calc_nb_saisies_visables = function (saisies) {
            return _(saisies).select({ recent: false, valide: false }).length;
        };
        $scope.detail_regroupement = function (group_id) {
            _($scope.enseignant.liste_regroupements).findWhere({ id: group_id });
        };
        $scope.filter_saisie = function (montre_valides, mois, selected_regroupements) {
            return function (saisie) {
                return (montre_valides || _(saisie.cours.date_validation).isNull())
                    && (_(mois).isNull() || saisie.mois == mois)
                    && (_.chain(selected_regroupements).pluck('id').contains(saisie.regroupement_id).value());
            };
        };
        $scope.graphiques = {
            pieChart: angular.copy(PIECHART_DEFINITION),
            multiBarChart: angular.copy(MULTIBARCHART_DEFINITION),
            populate: function (data) {
                $scope.graphiques.multiBarChart.data = [{
                        key: 'saisies non visées',
                        values: []
                    },
                    {
                        key: 'saisies visées',
                        values: []
                    }];
                $scope.graphiques.pieChart.data = [{
                        label: 'saisies non visées',
                        value: 0
                    },
                    {
                        label: 'saisies visées',
                        value: 0
                    }];
                _.chain(data)
                    .groupBy('regroupement_id')
                    .each(function (regroupement) {
                    var filled = regroupement.length;
                    var validated = _(regroupement).where({ valide: true }).length;
                    Annuaire.get_group(regroupement[0].regroupement_id)
                        .then(function success(response) {
                        _(regroupement).each(function (regroupement) { regroupement.group = response.data; });
                        $scope.graphiques.multiBarChart.data[0].values.push({
                            key: regroupement[0].group.name,
                            x: regroupement[0].group.name,
                            y: filled - validated
                        });
                        $scope.graphiques.multiBarChart.data[1].values.push({
                            key: regroupement[0].group.name,
                            x: regroupement[0].group.name,
                            y: validated
                        });
                    });
                    $scope.graphiques.pieChart.data[0].value += filled - validated;
                    $scope.graphiques.pieChart.data[1].value += validated;
                });
            }
        };
        $scope.select_all_regroupements = function () {
            $scope.selected_regroupements = $scope.enseignant.liste_regroupements;
            $scope.graphiques.populate($scope.raw_data);
        };
        $scope.select_no_regroupements = function () {
            $scope.selected_regroupements = [];
            $scope.graphiques.populate($scope.raw_data);
        };
        $scope.valide = function (saisie) {
            if (current_user.profil_actif.type === 'DIR') {
                var disable_toastr_1 = _(saisie).has('disable_toastr');
                saisie.cours.$valide().then(function (response) {
                    saisie.valide = !_(response.date_validation).isNull();
                    if (!$scope.montre_valides && !_(response.date_validation).isNull()) {
                        var date_validation_holder_1 = response.date_validation;
                        response.date_validation = null;
                        $timeout(function () { response.date_validation = date_validation_holder_1; }, 3000);
                    }
                    $scope.nb_saisies_visables = calc_nb_saisies_visables($scope.raw_data);
                    $scope.graphiques.populate($scope.raw_data);
                    if (!disable_toastr_1) {
                        toastr.success("S\u00E9quence p\u00E9dagogique " + (saisie.valide ? '' : 'dé-') + "vis\u00E9e.", 'Opération réussie');
                    }
                });
            }
        };
        $scope.valide_all = function () {
            swal({
                title: 'Tout viser ?',
                text: 'Cette action va viser toutes les saisies actuellement affichées à l\'écran.',
                type: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#ff6b55',
                confirmButtonText: 'Confirmer',
                cancelButtonText: 'Annuler'
            })
                .then(function confirm() {
                var counter = 0;
                _.chain($scope.raw_data)
                    .reject(function (saisie) { return saisie.valide || saisie.recent; })
                    .each(function (saisie) {
                    saisie.disable_toastr = true;
                    $scope.valide(saisie);
                    counter++;
                });
                if (counter > 0) {
                    var pluriel = counter > 1 ? 's' : '';
                    var message = counter + " s\u00E9quence" + pluriel + " p\u00E9dagogique" + pluriel + " vis\u00E9e" + pluriel + ".";
                    toastr.success(message, 'Opération réussie');
                }
            }, function cancel() { });
        };
        Annuaire.get_user($scope.enseignant_id)
            .then(function (response) {
            $scope.enseignant = response.data;
            $scope.enseignant.get_actual_groups()
                .then(function (response) {
                $scope.enseignant.liste_regroupements = _.chain(response)
                    .select(function (group) {
                    return group.type !== 'GPL'
                        && group.structure_id === $scope.current_user.profil_actif.structure_id;
                })
                    .uniq(function (group) { return group.id; })
                    .compact()
                    .value();
                $scope.enseignant.prof_principal = _.chain($scope.enseignant.groups)
                    .where({ type: 'PRI' })
                    .pluck('group_id')
                    .map(function (group_id) {
                    return _($scope.enseignant.liste_regroupements).findWhere({ id: group_id });
                })
                    .value();
                $scope.select_all_regroupements();
            });
            $scope.enseignant.get_actual_subjects()
                .then(function (response) {
                $scope.enseignant.liste_matieres = _.chain(response)
                    .uniq(function (subject) { return subject.id; })
                    .compact()
                    .value();
            });
            return API.get_enseignant($scope.current_user.profil_actif.structure_id, $scope.enseignant_id);
        })
            .then(function success(response) {
            var _2_semaines_avant = moment().subtract(2, 'weeks');
            $scope.raw_data = _(response.data.saisies).map(function (saisie, index) {
                saisie.index = index;
                saisie.cours = new Cours(saisie.cours);
                saisie.regroupement_id = parseInt(saisie.regroupement_id);
                saisie.month = moment(saisie.cours.date_cours).month();
                saisie.recent = moment(saisie.cours.date_cours).isAfter(_2_semaines_avant);
                saisie.matiere = _($scope.enseignant.liste_matieres).findWhere({ id: saisie.matiere_id });
                if (_(saisie.matiere).isUndefined()) {
                    saisie.matiere = Annuaire.get_subject(saisie.matiere_id);
                }
                return saisie;
            });
            $scope.graphiques.populate($scope.raw_data);
            $scope.nb_saisies_visables = calc_nb_saisies_visables($scope.raw_data);
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('DashboardTeachersCtrl', ['$scope', '$locale', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION',
    function ($scope, $locale, $q, API, Annuaire, current_user, PIECHART_DEFINITION) {
        $scope.scope = $scope;
        $scope.select_all_regroupements = function () {
            $scope.selected_regroupements = $scope.regroupements;
            $scope.filter_data();
        };
        $scope.select_no_regroupements = function () {
            $scope.selected_regroupements = [];
            $scope.filter_data();
        };
        $scope.filter_data = function () {
            _($scope.individualCharts.enseignants)
                .each(function (chart) {
                chart.display = !_.chain(chart.enseignant.details.groups)
                    .pluck('group_id')
                    .intersection(_($scope.selected_regroupements).pluck('id'))
                    .isEmpty()
                    .value();
            });
        };
        $scope.individualCharts = {
            enseignants: [],
            add: function (enseignant) {
                var chart = {
                    enseignant: enseignant,
                    display: true,
                    pieChart: angular.copy(PIECHART_DEFINITION)
                };
                chart.pieChart.data = [{
                        label: 'saisies non visées',
                        value: enseignant.filled - enseignant.validated
                    },
                    {
                        label: 'saisies visées',
                        value: enseignant.validated
                    }];
                $scope.individualCharts.enseignants.push(chart);
            }
        };
        Annuaire.get_groups_of_structures([current_user.profil_actif.structure_id])
            .then(function success(response) {
            $scope.regroupements = _(response.data).reject(function (group) {
                return group.type === 'GPL';
            });
            $scope.selected_regroupements = $scope.regroupements;
        });
        API.query_enseignants(current_user.profil_actif.structure_id)
            .then(function success(response) {
            $scope.raw_data = response.data;
            return Annuaire.get_users(_($scope.raw_data).pluck('enseignant_id'));
        })
            .then(function (response) {
            var enseignants_details = _(response.data).indexBy('id');
            _($scope.raw_data).each(function (enseignant) {
                enseignant.details = enseignants_details[enseignant.enseignant_id];
                var stats_enseignant = _(enseignant.classes).reduce(function (totaux, classe) {
                    var stats_classe = _(classe.statistiques).reduce(function (totaux, mois) {
                        return {
                            filled: totaux.filled + mois.filled,
                            validated: totaux.validated + mois.validated
                        };
                    }, { filled: 0, validated: 0 });
                    return {
                        filled: totaux.filled + stats_classe.filled,
                        validated: totaux.validated + stats_classe.validated
                    };
                }, { filled: 0, validated: 0 });
                enseignant.filled = stats_enseignant.filled;
                enseignant.validated = stats_enseignant.validated;
                $scope.individualCharts.add(enseignant);
            });
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('FooterCtrl', ['$scope', '$state', '$stateParams', '$sce', 'VERSION', 'CurrentUser',
    function ($scope, $state, $stateParams, $sce, VERSION, CurrentUser) {
        $scope.version = VERSION;
        CurrentUser.get().then(function (response) {
            $scope.current_user = response.data;
            $scope.save_and_reload = function () {
                CurrentUser.update_parameters($scope.current_user.parametrage_cahier_de_textes)
                    .then(function () {
                    $state.transitionTo($state.current, $stateParams, { reload: true, inherit: true, notify: true });
                });
            };
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('HeaderCtrl', ['$scope', '$state', 'CurrentUser', 'Redirection', '$sce', 'URL_DOCS',
    function ($scope, $state, CurrentUser, Redirection, $sce, URL_DOCS) {
        $scope.load_docs = window.location.hostname !== 'localhost';
        $scope.URL_DOCS_login = $sce.trustAsResourceUrl(URL_DOCS + "/login");
        $scope.embedded = window != window.top;
        CurrentUser.get().then(function (response) {
            $scope.current_user = response.data;
        });
        $scope.reload = function () {
            Redirection.doorman([]);
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('ImportCtrl', ['$scope', '$http', '$locale', '$sce', '$filter', 'fileUpload', 'moment', 'toastr', '$q',
    'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'VERSION',
    'Annuaire', 'Utils', 'Etablissements', 'CreneauxEmploiDuTemps', 'API', 'Matchable',
    'current_user',
    function ($scope, $http, $locale, $sce, $filter, fileUpload, moment, toastr, $q, APP_PATH, SEMAINES_VACANCES, ZONE, VERSION, Annuaire, Utils, Etablissements, CreneauxEmploiDuTemps, API, Matchable, current_user) {
        $scope.scope = $scope;
        $scope.jours_de_la_semaine = $locale.DATETIME_FORMATS.DAY;
        $scope.annee = $locale.DATETIME_FORMATS.MONTH;
        $scope.fichier = null;
        $scope.display_all = false;
        $scope.step = 0;
        $scope.report = {};
        $scope.ui = {
            show_detailed_creneaux: false,
            display_ready: true,
            display_problems: true,
            sortCreneauxBy: ['Jour'],
            sort_creneaux_by: function (criteria) {
                $scope.ui.sortCreneauxBy = $scope.ui.sortCreneauxBy[0] === criteria[0] ? _(criteria).map(function (sub_criteria) { return '-' + sub_criteria; }) : criteria;
            }
        };
        $scope.step_backward = function () {
            $scope.step--;
        };
        $scope.beautify_semainier = function (semainier) {
            var bsemainier = Utils.padEnd(semainier.toString(2), 53, '0');
            return '<div class="semainier-tooltip gris1">' +
                _.chain(Utils.overlay_semainier())
                    .sortBy(function (month) { return month.index; })
                    .map(function (month) {
                    var month_html = "<div class=\"month blanc\"><h5 class=\"month-name gris4\">" + month.label + "</h5>";
                    month_html += _(month.semaines).map(function (week) {
                        var week_html = '<span class="week';
                        if (Utils.sont_ce_les_vacances(week.semaine, ZONE)) {
                            week_html += ' vacances gris2';
                        }
                        if (bsemainier[week.semaine] === '1') {
                            week_html += ' active orange-moins';
                        }
                        week_html += "\">" + week.semaine + "</span>";
                        return week_html;
                    }).join('');
                    month_html += '</div>';
                    return month_html;
                })
                    .value()
                    .join('') +
                '<div class="clearfix"></div></div>';
        };
        $scope.filter_creneau = function (options, criteria) {
            return function (creneau) {
                if (!options.display_problems && !creneau.ready) {
                    return false;
                }
                if (!options.display_ready && creneau.ready) {
                    return false;
                }
                creneau.is_displayed = true;
                if (_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty()) {
                    creneau.is_displayed = creneau.is_displayed &&
                        !_(creneau).has('Classe') &&
                        !_(creneau).has('Groupe');
                }
                else if (_(criteria.classes).isEmpty() && !_(criteria.groupes).isEmpty()) {
                    creneau.is_displayed = creneau.is_displayed &&
                        !_(creneau).has('Classe') &&
                        _(creneau).has('Groupe') &&
                        _.chain(criteria.groupes).pluck('Ident').includes(creneau.Groupe.Ident).value();
                }
                else if (!_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty()) {
                    creneau.is_displayed = creneau.is_displayed &&
                        _(creneau).has('Classe') &&
                        !_(creneau).has('Groupe') &&
                        _.chain(criteria.classes).pluck('Ident').includes(creneau.Classe.Ident).value();
                }
                else {
                    creneau.is_displayed = creneau.is_displayed &&
                        ((_(creneau).has('Groupe') && _.chain(criteria.groupes).pluck('Ident').includes(creneau.Groupe.Ident).value()) ||
                            (_(creneau).has('Classe') && _.chain(criteria.classes).pluck('Ident').includes(creneau.Classe.Ident).value()));
                }
                if (!creneau.is_displayed) {
                    return false;
                }
                if (_(criteria.matieres).isEmpty()) {
                    creneau.is_displayed = creneau.is_displayed && !_(creneau).has('Matiere');
                }
                else {
                    creneau.is_displayed = creneau.is_displayed &&
                        _(creneau).has('Matiere') &&
                        _.chain(criteria.matieres).pluck('Ident').includes(creneau.Matiere.Ident).value();
                }
                if (!creneau.is_displayed) {
                    return false;
                }
                return creneau.is_displayed;
            };
        };
        var update_counters = function () {
            var filtered_creneaux = $filter('filter')($scope.creneaux, $scope.filter_creneau($scope.ui, $scope.selected));
            $scope.counters = {};
            $scope.counters.creneaux = $scope.creneaux.length;
            $scope.counters.creneaux_broken = _($scope.pronote.Cours[0].Cours).select(function (cours) { return !_(cours).has('Matiere') || !_(cours).has('Professeur') || (!_(cours).has('Classe') && !_(cours).has('Groupe')); }).length;
            $scope.counters.creneaux_not_ready = _($scope.creneaux).where({ ready: false }).length;
            $scope.counters.creneaux_ready = $scope.counters.creneaux - $scope.counters.creneaux_not_ready;
            $scope.counters.filtered_creneaux = filtered_creneaux.length;
            $scope.counters.filtered_creneaux_not_ready = _(filtered_creneaux).where({ ready: false }).length;
            $scope.counters.filtered_creneaux_ready = $scope.counters.filtered_creneaux - $scope.counters.filtered_creneaux_not_ready;
            $scope.counters.percent_creneaux_ready = $scope.counters.filtered_creneaux_ready / $scope.counters.filtered_creneaux;
        };
        var update_creneaux_readiness = function () {
            _($scope.creneaux).each(function (creneau) {
                creneau.readiness = {
                    matiere: !_($scope.pronote.matieres[creneau.Matiere.Ident]).isUndefined()
                        && !_($scope.pronote.matieres[creneau.Matiere.Ident].laclasse).isUndefined(),
                    salle: !_(creneau.Salle).isUndefined(),
                    classe: _(creneau).has('Classe')
                        && !_($scope.pronote.classes[creneau.Classe.Ident]).isUndefined()
                        && !_($scope.pronote.classes[creneau.Classe.Ident].laclasse).isUndefined(),
                    groupe_eleve: _(creneau).has('Groupe')
                        && !_($scope.pronote.groupes_eleves[creneau.Groupe.Ident]).isUndefined()
                        && !_($scope.pronote.groupes_eleves[creneau.Groupe.Ident].laclasse).isUndefined()
                };
                creneau.ready = creneau.readiness.matiere && (creneau.readiness.classe || creneau.readiness.groupe_eleve);
            });
            update_counters();
        };
        var hash_me = function (item) {
            var get_type = function (item) {
                if (_(item).has('PartieDeClass')) {
                    return 'regroupement';
                }
                else if (_(item).has('Code')) {
                    return 'matiere';
                }
                else {
                    return 'unknown';
                }
            };
            return window.btoa(unescape(encodeURIComponent(get_type(item) + item.displayed_label)));
        };
        var load_data = function (fichier) {
            $scope.pronote = false;
            $scope.matcheable_data = [];
            var handle_error = function (response) {
                return $q.reject(response);
            };
            toastr.info('Déchiffrage du fichier');
            return fileUpload.uploadFileToUrl(fichier, APP_PATH + "/api/import/pronote/decrypt")
                .then(function success(response) {
                $scope.pronote = response.data;
                $scope.pronote.GrilleHoraire[0].DureePlace = parseInt($scope.pronote.GrilleHoraire[0].DureePlace);
                toastr.info('récupération des données de l\'établissement');
                return Etablissements.get({ uai: $scope.pronote.UAI }).$promise;
            }, handle_error)
                .then(function success(response) {
                $scope.etablissement_summary = response;
                _($scope.etablissement_summary.imports).each(function (i) { i.date_import = new Date(i.date_import); });
                return Annuaire.get_structure($scope.pronote.UAI);
            }, handle_error)
                .then(function success(response) {
                $scope.etablissement = {
                    classes: _(response.data.groups).where({ type: 'CLS' }),
                    groupes_eleves: _(response.data.groups).select({ type: 'GRP' })
                };
                _($scope.etablissement.groupes_eleves).each(function (regroupement) {
                    regroupement.libelle_aaf = regroupement.name.toUpperCase();
                    regroupement.displayed_label = regroupement.name;
                });
                _($scope.etablissement.classes).each(function (regroupement) {
                    regroupement.libelle_aaf = regroupement.name.toUpperCase();
                    regroupement.displayed_label = regroupement.name;
                });
                toastr.info('traitement des données des regroupements');
                return API.query_statistiques_regroupements(current_user.profil_actif.structure_id);
            }, handle_error)
                .then(function success(response) {
                _($scope.pronote.Classes[0].Classe)
                    .each(function (regroupement) {
                    regroupement.displayed_label = regroupement.Nom;
                    regroupement.laclasse = _($scope.etablissement.classes).findWhere({ libelle_aaf: regroupement.Nom.toUpperCase() });
                    if (_(regroupement.laclasse).isUndefined()) {
                        var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me(regroupement) });
                        if (!_(matched).isUndefined()) {
                            regroupement.laclasse = _($scope.etablissement.classes).findWhere({ id: matched.id_annuaire });
                        }
                    }
                    regroupement.edit = _(regroupement.laclasse).isUndefined();
                    var creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response.data).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                    regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;
                    if (!regroupement.edit) {
                        regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                    }
                });
                _($scope.pronote.Groupes[0].Groupe)
                    .each(function (regroupement) {
                    regroupement.displayed_label = regroupement.Nom;
                    regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere({ libelle_aaf: regroupement.Nom.toUpperCase() });
                    if (_(regroupement.laclasse).isUndefined()) {
                        var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me(regroupement) });
                        if (!_(matched).isUndefined()) {
                            regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere({ id: matched.id_annuaire });
                        }
                    }
                    regroupement.edit = _(regroupement.laclasse).isUndefined();
                    var creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                    regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;
                    if (!regroupement.edit) {
                        regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                    }
                });
                toastr.info('traitement des données des cours');
                $scope.creneaux = _.chain($scope.pronote.Cours[0].Cours)
                    .map(function (cours) {
                    return _.chain(cours.Matiere).map(function (matiere) {
                        var compute_cours = function (type_regroupement) {
                            return function (regroupement) {
                                var this_cours = angular.copy(cours);
                                this_cours.is_displayed = true;
                                this_cours.Matiere = matiere;
                                if (type_regroupement === 'Classe') {
                                    this_cours.Classe = regroupement;
                                    this_cours.Classe.Semaines = Utils.fix_semainier_pronote(this_cours.Classe.Semaines, $scope.pronote.AnneeScolaire[0].DateDebut);
                                }
                                else {
                                    this_cours.Groupe = regroupement;
                                    this_cours.Groupe.Semaines = Utils.fix_semainier_pronote(this_cours.Groupe.Semaines, $scope.pronote.AnneeScolaire[0].DateDebut);
                                }
                                if (_(cours).has('Salle')) {
                                    return _(cours.Salle).map(function (salle) {
                                        this_cours.Salle = salle;
                                        this_cours.Salle.Semaines = Utils.fix_semainier_pronote(this_cours.Salle.Semaines, $scope.pronote.AnneeScolaire[0].DateDebut);
                                        return this_cours;
                                    });
                                }
                                else {
                                    return this_cours;
                                }
                            };
                        };
                        return [_(cours.Classe).map(compute_cours('Classe')),
                            _(cours.Groupe).map(compute_cours('Groupe'))];
                    })
                        .flatten()
                        .uniq()
                        .value();
                })
                    .flatten()
                    .value();
                $scope.pronote.classes = Utils.groupByKey($scope.pronote.Classes[0].Classe, 'Ident');
                $scope.pronote.salles = Utils.groupByKey($scope.pronote.Salles[0].Salle, 'Ident');
                $scope.pronote.plages_horaires = Utils.groupByKey($scope.pronote.GrilleHoraire[0].PlacesParJour[0].Place, 'Numero');
                $scope.pronote.groupes_eleves = Utils.groupByKey($scope.pronote.Groupes[0].Groupe, 'Ident');
                $scope.matcheable_data.push({
                    title: 'Classes',
                    pronote: $scope.pronote.classes,
                    annuaire: $scope.etablissement.classes
                });
                $scope.matcheable_data.push({
                    title: 'Groupes d\'élèves',
                    pronote: $scope.pronote.groupes_eleves,
                    annuaire: $scope.etablissement.groupes_eleves
                });
                toastr.info('Récupération des matieres');
                return Annuaire.query_subjects();
            }, handle_error)
                .then(function success(response) {
                $scope.matieres = _(response.data).map(function (matiere) {
                    if (_(matiere.name).isNull()) {
                        matiere.name = '';
                    }
                    matiere.name = matiere.name.toUpperCase();
                    matiere.displayed_label = matiere.name;
                    return matiere;
                });
                _($scope.pronote.Matieres[0].Matiere)
                    .each(function (matiere) {
                    matiere.displayed_label = matiere.Libelle;
                    matiere.laclasse = _($scope.matieres).findWhere({ name: matiere.Libelle.toUpperCase() });
                    if (_(matiere.laclasse).isUndefined()) {
                        if (_(matiere.laclasse).isUndefined()) {
                            var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me(matiere) });
                            if (!_(matched).isUndefined()) {
                                matiere.laclasse = _($scope.matieres).findWhere({ id: matched.id_annuaire });
                            }
                        }
                    }
                    matiere.edit = _(matiere.laclasse).isUndefined();
                    if (!matiere.edit) {
                        matiere.laclasse.displayed_label = matiere.laclasse.name;
                    }
                });
                $scope.pronote.matieres = Utils.groupByKey($scope.pronote.Matieres[0].Matiere, 'Ident');
                $scope.matcheable_data.push({
                    title: 'Matières',
                    pronote: $scope.pronote.matieres,
                    annuaire: $scope.matieres
                });
                _($scope.matcheable_data).each(function (dataset) {
                    dataset.total = function () { return _(dataset.pronote).size(); };
                    dataset.unmatched = function () { return _(dataset.pronote).where({ laclasse: undefined }).length; };
                    dataset.percent_valid = function () { return (dataset.total() - dataset.unmatched()) / dataset.total(); };
                });
                $scope.selected = {
                    matieres: $scope.pronote.Matieres[0].Matiere,
                    classes: _($scope.pronote.Classes[0].Classe).where({ existing_creneaux: 0 }),
                    groupes: _($scope.pronote.Groupes[0].Groupe).where({ existing_creneaux: 0 })
                };
                update_creneaux_readiness();
                $scope.$watchCollection('selected', function () { update_counters(); });
            }, handle_error)
                .then(function success(response) {
                $scope.step++;
                return $q.resolve(true);
            }, handle_error);
        };
        var import_data = function () {
            var started_at = moment();
            var import_id = null;
            var handle_error = function (response) {
                return $q.reject(response);
            };
            $scope.report = {};
            var creneaux_emploi_du_temps = _($scope.creneaux).select(function (creneau) {
                return creneau.ready && creneau.is_displayed;
            });
            return $http.post(APP_PATH + "/api/import/log/start/?uai=" + $scope.pronote.UAI, { uai: $scope.pronote.UAI, type: 'client ' + VERSION, comment: '' })
                .then(function success(response) {
                import_id = response.data.id;
                var ct_etablissement = new Etablissements({
                    uai: $scope.pronote.UAI,
                    date_premier_jour_premiere_semaine: new Date($scope.pronote.AnneeScolaire[0].DatePremierJourSemaine1),
                    debut_annee_scolaire: new Date($scope.pronote.AnneeScolaire[0].DateDebut),
                    fin_annee_scolaire: new Date($scope.pronote.AnneeScolaire[0].DateFin)
                });
                return ct_etablissement.$save();
            }, handle_error)
                .then(function success(response) {
                $scope.report.etablissement = response;
                var preprocess_cahiers_de_textes = function (liste_regroupements) {
                    return _.chain(liste_regroupements)
                        .reject(function (regroupement) { return _(regroupement.laclasse).isUndefined(); })
                        .map(function (regroupement) {
                        return {
                            label: regroupement.laclasse.libelle_aaf,
                            regroupement_id: regroupement.laclasse.id,
                            debut_annee_scolaire: new Date($scope.pronote.AnneeScolaire[0].DateDebut),
                            fin_annee_scolaire: new Date($scope.pronote.AnneeScolaire[0].DateFin)
                        };
                    })
                        .value();
                };
                var regroupements = preprocess_cahiers_de_textes($scope.pronote.classes);
                regroupements.push(preprocess_cahiers_de_textes($scope.pronote.groupes_eleves));
                regroupements = _(regroupements).flatten();
                return $http.post(APP_PATH + "/api/cahiers_de_textes/bulk", { cahiers_de_textes: regroupements });
            }, handle_error)
                .then(function success(response) {
                $scope.report.cahiers_de_textes = response.data;
                toastr.info('Création des salles');
                var salles_to_import = _($scope.pronote.salles)
                    .map(function (salle) {
                    return {
                        uai: $scope.pronote.UAI,
                        identifiant: salle.Ident,
                        nom: salle.Nom
                    };
                });
                return $http.post(APP_PATH + "/api/salles/bulk", { salles: salles_to_import });
            }, handle_error)
                .then(function success(response) {
                $scope.report.salles = response.data;
                var creneaux_to_import = creneaux_emploi_du_temps.map(function (creneau) {
                    var heure_debut = Utils.libelleHeure_to_Moment($scope.pronote.plages_horaires[creneau.NumeroPlaceDebut].LibelleHeureDebut);
                    var pre_creneau = {
                        import_id: import_id,
                        jour_de_la_semaine: parseInt(creneau.Jour),
                        heure_debut: heure_debut.toISOString(),
                        heure_fin: heure_debut.add(parseInt(creneau.NombrePlaces) * parseInt($scope.pronote.GrilleHoraire[0].DureePlace), 'minutes').toISOString(),
                        matiere_id: $scope.pronote.matieres[creneau.Matiere.Ident].laclasse.id
                    };
                    if (_(creneau).has('Salle')) {
                        pre_creneau.salle_id = _($scope.report.salles).find({ identifiant: creneau.Salle.Ident }).id;
                        pre_creneau.semainier_salle = parseInt(creneau.Salle.Semaines);
                    }
                    if (_(creneau).has('Classe')) {
                        pre_creneau.regroupement_id = $scope.pronote.classes[creneau.Classe.Ident].laclasse.id;
                        pre_creneau.semainier_regroupement = parseInt(creneau.Classe.Semaines);
                    }
                    else {
                        pre_creneau.regroupement_id = $scope.pronote.groupes_eleves[creneau.Groupe.Ident].laclasse.id;
                        pre_creneau.semainier_regroupement = parseInt(creneau.Groupe.Semaines);
                    }
                    return pre_creneau;
                });
                toastr.info("Import de " + creneaux_to_import.length + " cr\u00E9neaux");
                var promises = [];
                while (creneaux_to_import.length > 0) {
                    promises.push($http.post(APP_PATH + "/api/creneaux_emploi_du_temps/bulk/", {
                        uai: $scope.pronote.UAI,
                        creneaux_emploi_du_temps: creneaux_to_import.splice(0, 500)
                    }));
                }
                return $q.all(promises);
            }, handle_error)
                .then(function success(response) {
                $scope.report.creneaux = _.chain(response).pluck('data').flatten().value();
                return $q.resolve($scope.report);
            }, handle_error);
        };
        $scope.match_this = function (item, uai) {
            var laclasse_id = _(item.laclasse).has('ent_id') ? item.laclasse.ent_id : item.laclasse.id;
            var m = new Matchable({
                uai: uai,
                hash_item: hash_me(item),
                id_annuaire: laclasse_id
            });
            m.$save().then(function () {
                update_creneaux_readiness();
            });
        };
        $scope.unmatch_this = function (item, uai) {
            Matchable.delete({
                uai: uai,
                hash_item: hash_me(item)
            }).$promise
                .then(function () {
                item.laclasse = null;
                update_creneaux_readiness();
            });
        };
        $scope.process_load = function (fichier) {
            swal({
                title: "Chargement des données...",
                text: "traitement en cours",
                type: "info",
                showLoaderOnConfirm: true,
                onOpen: function () {
                    swal.clickConfirm();
                },
                preConfirm: function () {
                    return new Promise(function (resolve) {
                        load_data(fichier).then(function success(response) {
                            swal.closeModal();
                        }, function error(response) {
                            console.log(response);
                            swal.closeModal();
                            swal({
                                title: 'Erreur :(',
                                text: response.data.error,
                                type: 'error'
                            });
                        });
                    });
                },
                allowOutsideClick: false
            });
        };
        $scope.validate_matches = function () {
            $scope.step++;
        };
        $scope.process_import = function () {
            swal({
                title: "Import des données...",
                text: "traitement en cours",
                type: "info",
                showLoaderOnConfirm: true,
                allowOutsideClick: false,
                onOpen: function () {
                    swal.clickConfirm();
                },
                preConfirm: function () {
                    return new Promise(function (resolve) {
                        import_data().then(function success(response) {
                            swal.closeModal();
                            $scope.step = 0;
                            swal({
                                title: "Import terminé",
                                html: "",
                                type: 'success'
                            });
                        }, function error(response) {
                            console.log(response);
                            swal.closeModal();
                            swal({
                                title: 'Erreur :(',
                                text: response.data.error,
                                type: 'error'
                            });
                        });
                    });
                }
            });
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('IndexCtrl', ['$scope', '$state', 'CurrentUser',
    function ($scope, $state, CurrentUser) {
        var ctrl = $scope;
        CurrentUser.get()
            .then(function (response) {
            var user = response.data;
            switch (user.profil_actif.type) {
                case 'DIR':
                    ctrl.tabs = [{
                            heading: 'Validation des saisies par enseignant',
                            uisref: 'enseignants',
                            css_class: 'glyphicon glyphicon-user',
                            active: true
                        },
                        {
                            heading: 'Emplois du Temps',
                            uisref: 'emploi_du_temps',
                            css_class: 'glyphicon glyphicon-calendar',
                            active: false
                        },
                        {
                            heading: 'Import Pronote',
                            uisref: 'import',
                            css_class: 'glyphicon glyphicon-import',
                            active: false
                        }];
                    break;
                case 'ENS':
                    ctrl.tabs = [{
                            heading: 'Cahier de textes',
                            uisref: 'emploi_du_temps',
                            css_class: 'glyphicon glyphicon-calendar',
                            active: true
                        },
                        {
                            heading: 'Statistiques',
                            uisref: 'stats',
                            css_class: 'glyphicon glyphicon-stats',
                            active: false
                        }];
                    break;
                case 'TUT':
                case 'ELV':
                    ctrl.tabs = [{
                            heading: 'Emploi du temps',
                            uisref: 'emploi_du_temps',
                            css_class: 'glyphicon glyphicon-calendar',
                            active: true
                        },
                        {
                            heading: 'Liste des devoirs',
                            uisref: 'devoirs',
                            css_class: 'glyphicon glyphicon-list',
                            active: false
                        }];
                    break;
                case 'ADM':
                    ctrl.tabs = [{
                            heading: 'Emplois du Temps',
                            uisref: 'emploi_du_temps',
                            css_class: 'glyphicon glyphicon-calendar',
                            active: true
                        },
                        {
                            heading: 'Import Pronote',
                            uisref: 'import',
                            css_class: 'glyphicon glyphicon-import',
                            active: false
                        }];
                    break;
                case 'EVS':
                    ctrl.tabs = [{
                            heading: 'Emplois du Temps',
                            uisref: 'emploi_du_temps',
                            css_class: 'glyphicon glyphicon-calendar',
                            active: true
                        }];
                    break;
                default:
                    ctrl.tabs = [];
            }
            _(ctrl.tabs).each(function (tab) {
                tab.active = tab.uisref == $state.current.name;
            });
            ctrl.set_active_tab = function (uisref) {
                _(ctrl.tabs).each(function (tab) {
                    tab.active = tab.uisref == uisref;
                });
            };
            ctrl.set_active_tab(ctrl.tabs[0].uisref);
            $state.go(ctrl.tabs[0].uisref);
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('PopupDisplayCtrl', ['$scope', '$sce', '$uibModalInstance', 'toastr', 'APP_PATH', 'Cours', 'Devoirs', 'CurrentUser',
    'titre', 'cours', 'devoirs',
    function ($scope, $sce, $uibModalInstance, toastr, APP_PATH, Cours, Devoirs, CurrentUser, matiere, cours, devoirs) {
        $scope.app_path = APP_PATH;
        $scope.matiere = matiere;
        $scope.date = null;
        if (!_(cours).isNull()) {
            $scope.cours = new Cours(cours);
            $scope.date = $scope.cours.date_cours;
            _(cours.devoirs).each(function (devoir) {
                devoir.tooltip = devoir.contenu;
                if (devoir.temps_estime > 0) {
                    devoir.tooltip = "<span><i class=\"picto temps\"></i>" + devoir.temps_estime * 5 + " minutes</span><hr>" + devoir.tooltip;
                }
                devoir.tooltip = $sce.trustAsHtml(devoir.tooltip);
            });
        }
        $scope.devoirs = devoirs.map(function (devoir) {
            devoir.matiere = matiere;
            return new Devoirs(devoir);
        });
        if (_($scope.date).isNull() && !_($scope.devoirs).isEmpty()) {
            $scope.date = $scope.devoirs[0].date_due;
        }
        $scope.fermer = function () {
            $uibModalInstance.close($scope);
        };
        CurrentUser.get().then(function (response) {
            $scope.current_user = response.data;
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('PopupEditionCtrl', ['$scope', '$filter', '$q', '$sce', '$uibModalInstance', '$locale', 'toastr', 'moment',
    'APP_PATH', 'URL_DOCS', 'SEMAINES_VACANCES', 'ZONE', 'POPUP_ACTIONS', 'LOCALHOST',
    'Documents', 'API', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs', 'CurrentUser', 'Utils',
    'cours', 'devoirs', 'creneau', 'raw_data', 'classes', 'matieres',
    function ($scope, $filter, $q, $sce, $uibModalInstance, $locale, toastr, moment, APP_PATH, URL_DOCS, SEMAINES_VACANCES, ZONE, POPUP_ACTIONS, LOCALHOST, Documents, API, CreneauxEmploiDuTemps, Cours, Devoirs, CurrentUser, Utils, cours, devoirs, creneau, raw_data, classes, matieres) {
        var ctrl = $scope;
        ctrl.scope = ctrl;
        ctrl.correctTimeZoneToGMT = function (date) {
            var timezoneOffset = new Date(date).getTimezoneOffset() / 60;
            date.setHours(date.getHours() + timezoneOffset);
            return date;
        };
        ctrl.app_path = APP_PATH;
        ctrl.ZONE = ZONE;
        ctrl.jours = _($locale.DATETIME_FORMATS.DAY).indexBy(function (jour) { return _($locale.DATETIME_FORMATS.DAY).indexOf(jour); });
        ctrl.classes = classes;
        ctrl.matieres = _(matieres).sortBy('name');
        ctrl.faulty_docs_app = false;
        ctrl.erreurs = [];
        ctrl.dirty = false;
        ctrl.mode_duplication = false;
        ctrl.actions_done = [];
        ctrl.creneau = creneau;
        ctrl.creneau.jour_de_la_semaine = '' + ctrl.creneau.jour_de_la_semaine;
        ctrl.mode_edition_creneau = ctrl.creneau.en_creation;
        ctrl.creneau.regroupement_id = parseInt(ctrl.creneau.regroupement_id);
        ctrl.creneau.previous_regroupement_id = ctrl.creneau.regroupement_id;
        ctrl.creneau.vierge = _(creneau.vierge).isUndefined();
        ctrl.selected_regroupement = _(ctrl.creneau.regroupement_id).isUndefined() ? _(ctrl.classes).first() : _(ctrl.classes).findWhere({ id: parseInt(ctrl.creneau.regroupement_id) });
        ctrl.selected_matiere = _(ctrl.creneau.matiere_id).isEmpty() ? _(ctrl.matieres).first() : _(ctrl.matieres).findWhere({ id: ctrl.creneau.matiere_id });
        if (ctrl.creneau.en_creation) {
            ctrl.creneau.tmp_heure_debut = ctrl.correctTimeZoneToGMT(ctrl.creneau.heure_debut);
            ctrl.creneau.tmp_heure_fin = ctrl.correctTimeZoneToGMT(ctrl.creneau.heure_fin);
        }
        else {
            ctrl.creneau.tmp_heure_debut = angular.copy(ctrl.creneau.heure_debut);
            ctrl.creneau.tmp_heure_fin = angular.copy(ctrl.creneau.heure_fin);
            _(ctrl.creneau.regroupements).each(function (regroupement) {
                regroupement.regroupement_id = parseInt(regroupement.regroupement_id);
            });
        }
        ctrl.creneau.tmp_heure_debut = moment(ctrl.creneau.tmp_heure_debut);
        ctrl.creneau.tmp_heure_fin = moment(ctrl.creneau.tmp_heure_fin);
        ctrl.creneau.n_week = moment(ctrl.creneau.tmp_heure_debut).week();
        var do_nothing = function () { };
        ctrl.formateCreneau = function (creneau) {
            var label = '';
            if (_(creneau).has('start')) {
                label += $filter('amDateFormat')(creneau.start, 'ddd DD MMM HH:mm') + " - " + $filter('amDateFormat')(creneau.end, 'HH:mm');
            }
            else {
                label += $filter('amDateFormat')(creneau.heure_debut, 'ddd DD MMM HH:mm') + " - " + $filter('amDateFormat')(creneau.heure_fin, 'HH:mm');
            }
            return label;
        };
        ctrl.correctTimeZone = function (date) {
            date = new Date(date);
            var timezoneOffset = date.getTimezoneOffset() / 60;
            date.setHours(date.getHours() - timezoneOffset);
            return date;
        };
        var create_cours = function (creneau) {
            var cours = new Cours({
                creneau_emploi_du_temps_id: creneau.id,
                date_cours: new Date(creneau.heure_debut).toISOString(),
                date_validation: null,
                enseignant_id: ctrl.current_user.id,
                contenu: ''
            });
            cours.devoirs = [];
            cours.create = true;
            return cours;
        };
        ctrl.is_dirty = function (item) {
            item = _(item).isUndefined() || _(item).isNull() ? null : item;
            ctrl.dirty = ctrl.dirty || (_(item).isNull() || (!_(item).isNull() && item.contenu.length > 0));
            if (!_(item).isNull()) {
                item.dirty = true;
            }
        };
        ctrl.overlay_semainier = Utils.overlay_semainier();
        ctrl.sont_ce_les_vacances = Utils.sont_ce_les_vacances;
        var semaines_toutes_actives = function () {
            var semainier = [];
            _(52).times(function (i) {
                if (!Utils.sont_ce_les_vacances(i + 1, ZONE)) {
                    semainier.push(1);
                }
                else {
                    semainier.push(0);
                }
            });
            return semainier;
        };
        ctrl.semaines_actives = { regroupement: [] };
        ctrl.templates_semainier = [
            {
                label: 'Tout',
                apply: function () {
                    ctrl.semaines_actives.regroupement = semaines_toutes_actives();
                }
            },
            {
                label: 'Semaine A',
                apply: function () {
                    var template = [];
                    var semaines_depuis_les_vacances = 0;
                    _(52).times(function (i) {
                        if (Utils.sont_ce_les_vacances(i + 1, ZONE)) {
                            semaines_depuis_les_vacances = 0;
                        }
                        else {
                            semaines_depuis_les_vacances++;
                        }
                        template.push((semaines_depuis_les_vacances % 2 == 1) ? 1 : 0);
                    });
                    ctrl.semaines_actives.regroupement = template;
                }
            },
            {
                label: 'Semaine B',
                apply: function () {
                    var template = [];
                    var semaines_depuis_les_vacances = 0;
                    _(52).times(function (i) {
                        if (Utils.sont_ce_les_vacances(i + 1, ZONE)) {
                            semaines_depuis_les_vacances = 0;
                        }
                        else {
                            semaines_depuis_les_vacances++;
                        }
                        template.push((semaines_depuis_les_vacances % 2 == 0) ? 1 : 0);
                    });
                    ctrl.semaines_actives.regroupement = template;
                }
            },
            {
                label: 'Unique',
                apply: function () {
                    var template = [];
                    _(52).times(function (week) {
                        template.push((week + 1 == ctrl.creneau.n_week) ? 1 : 0);
                    });
                    ctrl.semaines_actives.regroupement = template;
                }
            },
            {
                label: 'Inverser',
                apply: function () {
                    ctrl.semaines_actives.regroupement = _(ctrl.semaines_actives.regroupement).map(function (w, i) {
                        return ((w == 0) && !Utils.sont_ce_les_vacances(i + 1, ZONE)) ? 1 : 0;
                    });
                }
            },
            {
                label: 'Réinitialiser',
                apply: function () {
                    ctrl.semaines_actives.regroupement = ctrl.creneau.en_creation ? semaines_toutes_actives() : Utils.fixnum_to_bitfield(creneau.semainier);
                }
            }
        ];
        _(ctrl.templates_semainier).findWhere({ label: 'Réinitialiser' }).apply();
        ctrl.fermer = function () {
            if (ctrl.cours && ctrl.cours.deleted) {
                Documents.rm(_(ctrl.cours.ressources).pluck('hash'));
            }
            var clean_ressources_devoirs = function (devoirs) {
                if (devoirs) {
                    _.chain(devoirs)
                        .where({ deleted: true })
                        .each(function (devoir) {
                        Documents.rm(_(devoir.ressources).pluck('hash'));
                    });
                }
            };
            if (ctrl.cours) {
                clean_ressources_devoirs(ctrl.cours.devoirs);
            }
            if (ctrl.devoirs) {
                clean_ressources_devoirs(ctrl.devoirs);
            }
            $uibModalInstance.close(ctrl);
        };
        ctrl.effacer_creneau = function () {
            var do_it = function () {
                CreneauxEmploiDuTemps.delete({
                    id: ctrl.creneau.id,
                    date_creneau: ctrl.creneau.heure_debut
                })
                    .$promise.then(function () {
                    ctrl.actions_done.push(POPUP_ACTIONS.CRENEAU_DELETED);
                    ctrl.fermer();
                });
            };
            if (ctrl.dirty) {
                swal({
                    title: 'Ceci supprimera le créneau à compter du ' + $filter('amDateFormat')(creneau.heure_debut, 'dddd D MMMM YYYY'),
                    text: 'Le créneau avec ses séquences pédagogiques et devoirs associés restera visible pour les dates antérieures.',
                    type: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#ff6b55',
                    confirmButtonText: 'Confirmer',
                    cancelButtonText: 'Annuler'
                }).then(do_it, do_nothing);
            }
            else {
                do_it();
            }
        };
        ctrl.annuler = function () {
            var do_it = function () {
                if (ctrl.creneau.en_creation) {
                    ctrl.effacer_creneau();
                }
                else {
                    ctrl.dirty = false;
                    if (ctrl.actions_done.length == 0) {
                        ctrl.actions_done.push(POPUP_ACTIONS.CANCELLED);
                    }
                    ctrl.fermer();
                }
            };
            if (ctrl.dirty) {
                swal({
                    title: 'Êtes-vous sur ?',
                    text: 'Les modifications que vous avez faites dans cette fenêtre seront perdues.',
                    type: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#ff6b55',
                    confirmButtonText: 'Confirmer',
                    cancelButtonText: 'Annuler'
                }).then(do_it, do_nothing);
            }
            else {
                do_it();
            }
        };
        ctrl.valider = function () {
            ctrl.erreurs = [];
            var promesses = [];
            if (ctrl.mode_edition_creneau) {
                ctrl.creneau.matiere_id = ctrl.selected_matiere.id;
                ctrl.creneau.regroupement_id = ctrl.selected_regroupement.id;
                if (ctrl.creneau.tmp_heure_debut > ctrl.creneau.tmp_heure_fin) {
                    var tmp = ctrl.creneau.tmp_heure_debut;
                    ctrl.creneau.tmp_heure_debut = ctrl.creneau.tmp_heure_fin;
                    ctrl.creneau.tmp_heure_fin = tmp;
                }
                ctrl.creneau.heure_debut = ctrl.correctTimeZone(ctrl.creneau.tmp_heure_debut);
                ctrl.creneau.heure_fin = ctrl.correctTimeZone(ctrl.creneau.tmp_heure_fin);
                ctrl.creneau.semainier_regroupement = Utils.bitfield_to_fixnum(ctrl.semaines_actives.regroupement);
                ctrl.creneau.$update();
                ctrl.actions_done.push(POPUP_ACTIONS.CRENEAU_MODIFIED);
            }
            else {
                var valider_devoirs_1 = function (devoirs, cours) {
                    _.chain(devoirs)
                        .where({ dirty: true })
                        .each(function (devoir) {
                        var prom = $q.defer();
                        var treat_error = function error(response) {
                            ctrl.erreurs.unshift({
                                status: response.status,
                                message: response.data.error
                            });
                            prom.reject(response);
                        };
                        var treat_success = function (action) {
                            return function success(result) {
                                devoir.id = result.id;
                                prom.resolve(result);
                                ctrl.actions_done.push(action);
                            };
                        };
                        if (devoir.create) {
                            devoir.regroupement_id = ctrl.selected_regroupement.id;
                            if (!_(cours).isNull()) {
                                devoir.cours_id = cours.id;
                            }
                            if (!_(devoir).has('contenu')) {
                                devoir.contenu = '';
                            }
                            devoir.$save().then(treat_success(POPUP_ACTIONS.DEVOIR_CREATED), treat_error);
                        }
                        else {
                            devoir.$update().then(treat_success(POPUP_ACTIONS.DEVOIR_MODIFIED), treat_error);
                        }
                        promesses.push(prom.promise);
                    });
                };
                if ((ctrl.cours.contenu.length > 0 || (_(ctrl.cours).has('ressources') && ctrl.cours.ressources.length > 0)) || (ctrl.cours.devoirs.length > 0)) {
                    var cours_devoirs_1 = _(ctrl.cours.devoirs).map(function (devoir) {
                        return new Devoirs(devoir);
                    });
                    if (ctrl.cours.editable) {
                        var promesse = $q.when(true);
                        if (ctrl.cours.create) {
                            ctrl.cours.regroupement_id = ctrl.selected_regroupement.id;
                            ctrl.cours.creneau_emploi_du_temps_id = ctrl.creneau.id;
                            promesse = ctrl.cours.$save();
                            ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_CREATED);
                        }
                        else {
                            promesse = ctrl.cours.$update();
                            ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_MODIFIED);
                        }
                        if (cours_devoirs_1.length > 0) {
                            promesse.then(function (cours_from_DB) {
                                valider_devoirs_1(cours_devoirs_1, cours_from_DB);
                            });
                        }
                    }
                    else {
                        valider_devoirs_1(cours_devoirs_1, ctrl.cours);
                    }
                }
                valider_devoirs_1(ctrl.devoirs, null);
            }
            $q.all(promesses).then(ctrl.fermer);
        };
        var init_cours_existant = function (cours) { };
        if (!ctrl.creneau.en_creation) {
            ctrl.estimation_over = function (d, value) {
                d.overValue = value;
                d.minutes = 5 * value;
            };
            ctrl.estimation_leave = function (d) {
                ctrl.estimation_over(d, d.temps_estime);
            };
            API.query_types_de_devoir()
                .then(function (response) {
                ctrl.types_de_devoir = response.data;
            });
            init_cours_existant = function (cours) {
                ctrl.cours = Cours.get({ id: cours.id });
                ctrl.cours.$promise.then(function (cours) {
                    ctrl.cours.editable = _(ctrl.cours.date_validation).isNull() && _(['ENS', 'DOC']).includes(ctrl.current_user.profil_actif.type) && ctrl.cours.enseignant_id === ctrl.current_user.id;
                    if (!ctrl.cours.editable) {
                        ctrl.cours.contenu = $sce.trustAsHtml(ctrl.cours.contenu);
                    }
                    cours.devoirs = _.chain(cours.devoirs)
                        .select(function (devoir) {
                        return _.chain(devoirs).findWhere({ id: devoir.id }).isUndefined().value();
                    })
                        .map(function (devoir) {
                        return Devoirs.get({ id: devoir.id });
                    })
                        .value();
                    _(cours.devoirs).each(function (devoir) {
                        devoir.$promise.then(function (d) {
                            ctrl.estimation_leave(d);
                            d.tooltip = "<em>" + $filter('amDateFormat')(d.date_due, 'dddd D MMMM YYYY') + "</em><hr />" + d.contenu;
                            if (d.temps_estime > 0) {
                                d.tooltip = "<span><i class=\"picto temps\"></i>" + d.temps_estime * 5 + " minutes</span><hr />" + d.tooltip;
                            }
                            d.tooltip = $sce.trustAsHtml("<div>" + d.tooltip + "</div>");
                            if (ctrl.creneau.etranger) {
                                d.contenu = $sce.trustAsHtml(d.contenu);
                            }
                        });
                    });
                    $q.all(ctrl.devoirs).then(function () {
                        ctrl.cours.devoirs = _(ctrl.cours.devoirs).filter(function (devoir) {
                            return _.chain(ctrl.devoirs).findWhere({ id: devoir.id }).isUndefined().value();
                        });
                    });
                    ctrl.cours.$promise.then(function () {
                        _(ctrl.cours.ressources).each(function (ressource) {
                            ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                        });
                    });
                    _(ctrl.cours.devoirs).each(function (devoir) {
                        devoir.$promise.then(function () {
                            _(devoir.ressources).each(function (ressource) {
                                ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                            });
                        });
                    });
                });
                ctrl.cours.create = false;
            };
            ctrl.devoirs = devoirs.map(function (devoir) {
                var devoir_from_DB = Devoirs.get({ id: devoir.id });
                return devoir_from_DB;
            });
            _(ctrl.devoirs).each(function (devoir) {
                devoir.$promise.then(function () {
                    ctrl.estimation_leave(devoir);
                    _(devoir.ressources).each(function (ressource) {
                        ressource.url = $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + ressource.hash);
                    });
                    if (ctrl.creneau.etranger) {
                        devoir.contenu = $sce.trustAsHtml(devoir.contenu);
                    }
                });
            });
            ctrl.set_creneau_date_due = function (devoir) {
                var creneau_choisi = _(ctrl.creneaux_devoirs_possibles).findWhere({
                    date_due: devoir.date_due
                });
                devoir.creneau_emploi_du_temps_id = creneau_choisi.id;
                ctrl.is_dirty(devoir);
            };
            var liste_creneaux_similaires_1 = function (creneau, n_semaines_before, n_semaines_after) {
                return API.get_creneaux_emploi_du_temps_similaires({
                    id: creneau.id,
                    debut: moment(creneau.heure_debut.toISOString()).subtract(n_semaines_before, 'weeks').toDate(),
                    fin: moment(creneau.heure_debut.toISOString()).add(n_semaines_after, 'weeks').toDate()
                });
            };
            liste_creneaux_similaires_1(ctrl.creneau, 2, 8)
                .then(function (response) {
                ctrl.creneaux_devoirs_possibles_duplication = [];
                ctrl.creneaux_similaires = _.chain(response.data)
                    .reject(function (creneau) { return _(creneau.regroupement_id).isUndefined() || creneau.has_cours; })
                    .map(function (creneau) {
                    creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                    creneau.heure_debut = new Date(creneau.heure_debut);
                    creneau.heure_fin = new Date(creneau.heure_fin);
                    return creneau;
                })
                    .value();
                ctrl.creneaux_similaires.selected = [];
            });
            liste_creneaux_similaires_1(ctrl.creneau, 0, 8)
                .then(function (response) {
                if (_(response.data).isEmpty()) {
                    response.data = [ctrl.creneau];
                }
                ctrl.creneaux_devoirs_possibles = _.chain(response.data)
                    .select(function (creneau) { return creneau.regroupement_id === ctrl.creneau.regroupement_id; })
                    .map(function (creneau) {
                    creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                    creneau.semaine = moment(creneau.start).from(moment(ctrl.creneau.heure_debut));
                    creneau.heure_debut = new Date(creneau.heure_debut);
                    creneau.heure_fin = new Date(creneau.heure_fin);
                    creneau.date_due = $filter('date')(creneau.heure_debut, 'y-MM-dd');
                    return creneau;
                })
                    .sortBy(function (creneau) {
                    return creneau.start;
                })
                    .value();
                if (ctrl.creneaux_devoirs_possibles.length > 1) {
                    ctrl.creneaux_devoirs_possibles = _(ctrl.creneaux_devoirs_possibles)
                        .select(function (creneau) {
                        return creneau.heure_debut.toISOString() != ctrl.creneau.heure_debut.toISOString();
                    });
                }
            });
            ctrl.cartable = {};
            ctrl.cartable.expandedNodes = [];
            ctrl.treeOptions = {
                dirSelectable: false
            };
            Documents.list_files()
                .then(function (response) {
                if (_(response.data).has('files')) {
                    ctrl.cartable = response.data;
                    ctrl.cartable.files = _(response.data.files).select(function (file) {
                        return _(file.phash).isNull();
                    });
                    ctrl.cartable.expandedNodes = [];
                }
            }, function error() { });
            ctrl.consume_Documents_response_callback = function (item) {
                return function (response) {
                    ctrl.erreurs = [];
                    if (!_(response.error).isEmpty()) {
                        ctrl.erreurs.push({ message: response.error });
                    }
                    else {
                        var _item = _(response.added).first();
                        item.ressources.push({
                            name: _item.name,
                            hash: _item.hash,
                            url: $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + _item.hash)
                        });
                        ctrl.is_dirty(item);
                        if (!_(response.removed).isEmpty()) {
                            item.ressources = _(item.ressources).reject(function (ressource) {
                                return _(response.removed).includes(ressource.hash);
                            });
                        }
                    }
                };
            };
            ctrl.upload_and_add_ressource = function (item, fichiers) {
                if (item.ressources == undefined) {
                    item.ressources = [];
                }
                Documents.upload_dans_cahier_de_textes(ctrl.selected_regroupement, fichiers)
                    .then(function success(responses) {
                    responses.forEach(function (response) {
                        ctrl.consume_Documents_response_callback(item)(response.data);
                    });
                });
            };
            ctrl.remove_ressource = function (item, hash) {
                Documents.rm([hash]);
                item.ressources = _(item.ressources).reject(function (ressource) {
                    return ressource.hash == hash;
                });
                ctrl.is_dirty(item);
            };
            ctrl.effacer_cours = function () {
                ctrl.cours.$delete()
                    .then(function () {
                    ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DELETED);
                    init_cours_existant(ctrl.cours);
                });
            };
            ctrl.effacer_devoir = function (devoir) {
                if (_(devoir).has('id')) {
                    devoir.$delete().then(function () {
                        ctrl.actions_done.push(POPUP_ACTIONS.DEVOIR_DELETED);
                    });
                }
                else {
                    devoir.deleted = true;
                }
            };
            ctrl.ajout_devoir = function (where, creneau_cible) {
                if (_(creneau_cible).isNull() || _(creneau_cible).isUndefined() || ctrl.creneaux_devoirs_possibles.length < 1) {
                    creneau_cible = ctrl.creneau;
                }
                else if (creneau_cible === 'next') {
                    if (ctrl.creneaux_devoirs_possibles.length > 1) {
                        creneau_cible = _.chain(ctrl.creneaux_devoirs_possibles)
                            .select(function (creneau) {
                            return creneau.heure_debut > ctrl.creneau.heure_debut;
                        })
                            .head()
                            .value();
                    }
                    else {
                        creneau_cible = _(ctrl.creneaux_devoirs_possibles).first();
                    }
                }
                var devoir = new Devoirs({
                    cours_id: ctrl.cours.id,
                    date_due: $filter('date')(creneau_cible.heure_debut, 'yyyy-MM-dd'),
                    type_devoir_id: _(ctrl.types_de_devoir).last().id,
                    creneau_emploi_du_temps_id: creneau_cible.id,
                    contenu: ''
                });
                devoir.create = true;
                devoir.dirty = true;
                where.unshift(devoir);
            };
            ctrl.switch_to_duplication_mode = function () {
                ctrl.mode_duplication = true;
            };
            ctrl.ok_go_for_duplication = false;
            ctrl.are_we_go_for_duplication = function () {
                ctrl.ok_go_for_duplication = !_(ctrl.creneaux_similaires.selected).isEmpty()
                    && _(ctrl.cours.devoirs).reduce(function (is_it, devoir) { return is_it && _(devoir).has('creneau_cible'); }, true);
            };
            ctrl.creneau_cible_duplication_SP_updated = function () {
                liste_creneaux_similaires_1(ctrl.creneaux_similaires.selected, 0, 4)
                    .then(function (response) {
                    ctrl.creneaux_devoirs_possibles_duplication = _.chain(response.data)
                        .select(function (creneau) { return creneau.regroupement_id == ctrl.creneaux_similaires.selected.regroupement_id; })
                        .map(function (creneau) {
                        creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                        creneau.date_due = $filter('date')(creneau.start, 'y-MM-dd');
                        creneau.semaine = moment(creneau.start).from(moment(ctrl.creneau.heure_debut), true) + " plus tard";
                        creneau.heure_debut = new Date(creneau.heure_debut);
                        creneau.heure_fin = new Date(creneau.heure_fin);
                        return creneau;
                    })
                        .value();
                });
                ctrl.are_we_go_for_duplication();
            };
            ctrl.dupliquer = function () {
                var devoirs = angular.copy(ctrl.cours.devoirs);
                ctrl.cours.$copie({
                    regroupement_id: ctrl.creneaux_similaires.selected.regroupement_id,
                    creneau_emploi_du_temps_id: ctrl.creneaux_similaires.selected.creneau_emploi_du_temps_id,
                    date: ctrl.creneaux_similaires.selected.start
                }).then(function () {
                    ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DUPLICATED);
                    toastr.success('', 'Séquence pédagogique copiée.');
                    _(devoirs).each(function (devoir) {
                        devoir.$copie({
                            cours_id: ctrl.cours.copie_id,
                            creneau_emploi_du_temps_id: devoir.creneau_cible.id,
                            date_due: devoir.creneau_cible.date_due
                        })
                            .then(function () {
                            ctrl.actions_done.push(POPUP_ACTIONS.DEVOIR_DUPLICATED);
                            toastr.success('', 'Devoir copié.');
                            devoir.creneau_cible = [];
                        });
                    });
                    ctrl.creneaux_similaires = _(ctrl.creneaux_similaires).reject(function (creneau) {
                        return creneau.id + creneau.start == ctrl.creneaux_similaires.selected.id + ctrl.creneaux_similaires.selected.start;
                    });
                    ctrl.creneaux_similaires.selected = [];
                    init_cours_existant(ctrl.cours);
                    swal({
                        title: 'Créneau copié !',
                        type: 'success',
                        timer: 2000,
                        showCancelButton: false,
                        confirmButtonColor: '#ff6b55',
                        confirmButtonText: 'Fermer'
                    });
                });
            };
            ctrl.switch_to_modification_mode = function () {
                ctrl.mode_edition_creneau = false;
                ctrl.mode_duplication = false;
            };
            ctrl.switch_to_creneau_edition = function () {
                ctrl.dirty = true;
                ctrl.erreurs = [];
                ctrl.mode_edition_creneau = true;
            };
        }
        CurrentUser.get().then(function (response) {
            ctrl.current_user = response.data;
            if (!ctrl.current_user.parametrage_cahier_de_textes.affichage_week_ends) {
                delete ctrl.jours[0];
                delete ctrl.jours[6];
            }
            ctrl.creneau.mine = ctrl.creneau.en_creation || _.chain(ctrl.current_user.profil_actif.matieres).pluck('id').include(ctrl.creneau.matiere_id).value();
            ctrl.creneau.can_add_homework = _(['ENS', 'DOC']).includes(ctrl.current_user.profil_actif.type) && _.chain(ctrl.current_user.profil_actif.matieres).pluck('id').include(ctrl.creneau.matiere_id).value();
            ctrl.creneau.etranger = !ctrl.current_user.profil_actif.admin && !ctrl.creneau.en_creation && !ctrl.creneau.mine;
            if (_(cours).isNull()) {
                if (!ctrl.creneau.etranger) {
                    ctrl.cours = create_cours(creneau);
                    ctrl.cours.editable = true;
                }
            }
            else {
                init_cours_existant(cours);
            }
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .controller('TextBookCtrl', ['$scope', 'moment', '$state', '$q', '$locale',
    'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'PopupsCreneau', 'CreneauxEmploiDuTemps', 'Utils', 'Annuaire', 'CurrentUser', 'API',
    'current_user',
    function ($scope, moment, $state, $q, $locale, APP_PATH, SEMAINES_VACANCES, ZONE, PopupsCreneau, CreneauxEmploiDuTemps, Utils, Annuaire, CurrentUser, API, current_user) {
        $scope.scope = $scope;
        $scope.current_user = current_user;
        if ($scope.current_user.profil_actif.type === 'TUT' && _($scope.current_user.enfant_actif).isUndefined()) {
            $scope.current_user.enfant_actif = $scope.current_user.enfants[0];
        }
        $scope.zone = ZONE;
        $scope.emploi_du_temps = angular.element('#emploi_du_temps');
        var popup_ouverte = false;
        var first_load = true;
        $scope.uniquement_mes_creneaux = !_(['EVS', 'DIR', 'ADM']).contains($scope.current_user.profil_actif.type);
        var set_preferred_view = function (view) {
            $scope.current_user.parametrage_cahier_de_textes.preferredView = view;
            CurrentUser.update_parameters($scope.current_user.parametrage_cahier_de_textes);
        };
        if (!_($scope.current_user.parametrage_cahier_de_textes).has('preferredView')) {
            set_preferred_view('timetableWeek');
        }
        $scope.filter_data = function (raw_data) {
            if (_(['EVS', 'DIR', 'ADM']).contains($scope.current_user.profil_actif.type)) {
                return filter_by_regroupement(raw_data, $scope.selected_regroupements);
            }
            else if (_(['ENS', 'DOC']).contains($scope.current_user.profil_actif.type)) {
                return filter_by_matieres(filter_by_regroupement(raw_data, $scope.selected_regroupements), $scope.current_user.extract_subjects_ids(), $scope.uniquement_mes_creneaux);
            }
            else {
                return raw_data;
            }
        };
        $scope.prev = function () { $scope.emploi_du_temps.fullCalendar('prev'); };
        $scope.next = function () { $scope.emploi_du_temps.fullCalendar('next'); };
        $scope.select_all_regroupements = function () {
            $scope.selected_regroupements = $scope.current_user.actual_groups;
            $scope.refresh_calendar();
        };
        $scope.select_no_regroupements = function () {
            $scope.selected_regroupements = [];
            $scope.refresh_calendar();
        };
        var popup_callback = function (scope_popup) {
            var view = $scope.emploi_du_temps.fullCalendar('getView');
            retrieve_data(view.start.toDate(), view.end.toDate());
        };
        var to_fullcalendar_events = function (filtered_data) {
            var CalendarEvent = function (event) {
                var fc_event = this;
                fc_event.details = event;
                fc_event.allDay = false;
                fc_event.regroupement = _($scope.current_period_groups).findWhere({ id: parseInt(fc_event.details.regroupement_id) });
                fc_event.title = (_(fc_event.regroupement).isUndefined()) ? '' : fc_event.regroupement.name;
                fc_event.matiere = _($scope.subjects).findWhere({ id: fc_event.details.matiere_id });
                fc_event.has_resources = _(event.cours).has('ressources') && event.cours.ressources.length > 0;
                fc_event.temps_estime = 0;
                fc_event.start = moment(event.start);
                fc_event.end = moment(event.end);
                fc_event.className = 'saisie-vide';
                if (!_(fc_event.matiere).isUndefined()) {
                    fc_event.title += ' - ' + fc_event.matiere.name;
                }
                if (!_(event.cours).isNull()) {
                    _(event.cours.devoirs).each(function (devoir) {
                        fc_event.has_ressources = fc_event.has_ressources || _(devoir).has('ressources') && devoir.ressources.length > 0;
                    });
                }
                _(event.devoirs).each(function (devoir) {
                    fc_event.has_ressources = fc_event.has_ressources || _(devoir).has('ressources') && devoir.ressources.length > 0;
                    if (!_(devoir.temps_estime).isNull()) {
                        fc_event.temps_estime += devoir.temps_estime;
                        if (fc_event.temps_estime > 15) {
                            fc_event.temps_estime = 15;
                        }
                    }
                });
                if (event.devoirs.length > 0) {
                    var highest_type_de_devoir = _.chain(event.devoirs).pluck('type_devoir_id').sort().first().value();
                    switch (highest_type_de_devoir) {
                        case 1:
                            fc_event.className = 'edt-devoir-note-surveille';
                            break;
                        case 2:
                            fc_event.className = 'edt-devoir-note-maison';
                            break;
                        default:
                            if ($scope.current_user.profil_actif.type === 'ELV') {
                                fc_event.className = _.chain(event.devoirs).pluck('fait').contains(true).value() ? 'edt-devoir-fait' : 'edt-devoir-a-faire';
                            }
                    }
                }
                else {
                    fc_event.className = 'edt-cours';
                    if (!_(event.cours).isNull() && !_(event.cours.date_validation).isNull() && ($scope.current_user.profil_actif.type === 'ENS' && $scope.current_user.profil_actif.type === 'DOC')) {
                        fc_event.className += '-valide';
                    }
                    else if (!_(event.cours).isNull()) {
                        fc_event.className += '-saisie';
                    }
                }
                if (((_(['ELV', 'TUT', 'EVS', 'DIR', 'ADM']).contains($scope.current_user.profil_actif.type)) && _(event.cours).isNull() && _(event.devoirs).isEmpty())) {
                    fc_event.className += ' unclickable-event';
                }
                else {
                    fc_event.className += ' clickable-event';
                }
            };
            return _(filtered_data).map(function (event) {
                return new CalendarEvent(event);
            });
        };
        $scope.refresh_calendar = function () {
            $scope.calendar.events[0] = to_fullcalendar_events($scope.filter_data($scope.raw_data));
        };
        var retrieve_data = function (from_date, to_date) {
            if ($scope.current_user.profil_actif.type != 'TUT' || $scope.current_user.enfant_actif) {
                API.get_emploi_du_temps(from_date, to_date, $scope.current_user.profil_actif.structure_id, $scope.current_user.profil_actif.type === 'TUT' ? $scope.current_user.enfant_actif.child_id : null)
                    .then(function success(response) {
                    $scope.raw_data = response.data;
                    var groups_ids = _.chain($scope.raw_data).pluck('regroupement_id').uniq().value();
                    var subjects_ids = _.chain($scope.raw_data).pluck('matiere_id').uniq().value();
                    var promise = _(groups_ids).isEmpty() ? $q.resolve([]) : Annuaire.get_groups(groups_ids);
                    promise
                        .then(function (response) {
                        $scope.current_period_groups = response.data;
                        return Annuaire.get_subjects(subjects_ids);
                    })
                        .then(function (response) {
                        $scope.subjects = response.data;
                        $scope.refresh_calendar();
                    });
                });
            }
        };
        $scope.current_user.get_actual_groups()
            .then(function (actual_groups) {
            if ($scope.uniquement_mes_creneaux) {
                $scope.selected_regroupements = $scope.current_user.actual_groups;
            }
            else {
                $scope.selected_regroupements = [$scope.current_user.actual_groups[0]];
            }
        });
        $scope.extraEventSignature = function (event) {
            return '' + event.matiere;
        };
        var filter_by_regroupement = function (raw_data, selected_regroupements) {
            return _(raw_data).filter(function (creneau) {
                return _.chain(selected_regroupements).pluck('id').contains(parseInt(creneau.regroupement_id)).value();
            });
        };
        var filter_by_matieres = function (raw_data, subjects_ids, active) {
            return !active ? raw_data : _(raw_data).filter(function (creneau) {
                return _(subjects_ids).contains(creneau.matiere_id) || creneau.matiere_id == '';
            });
        };
        if ($scope.current_user.profil_actif.type === 'TUT') {
            if ($scope.current_user.enfants.length == 0) {
                swal({
                    title: 'Erreur',
                    text: 'Aucun enfant configuré pour ce profil.',
                    type: 'error',
                    showCancelButton: false,
                    confirmButtonColor: '#ff6b55',
                    confirmButtonText: 'Fermer'
                });
            }
            else {
                $scope.uid_enfant_actif = $scope.current_user.enfant_actif.child_id;
                $scope.reload_data = popup_callback;
            }
        }
        var can_edit = _(['ENS', 'DOC', 'DIR', 'ADM']).contains($scope.current_user.profil_actif.type) || $scope.current_user.profil_actif.admin;
        $scope.calendar = {
            options: {
                lang: 'fr',
                locale: 'fr',
                height: 600,
                header: {
                    left: _(['ENS', 'DOC']).contains($scope.current_user.profil_actif.type) ? 'timetableWeek,textbookWeek' : '',
                    center: 'title',
                    right: 'today prev,next'
                },
                firstDay: 1,
                minTime: '07:00:00',
                maxTime: '19:00:00',
                businessHours: {
                    start: '7:00',
                    end: '19:00',
                    dow: [1, 2, 3, 4, 5]
                },
                titleFormat: 'D MMM YYYY, [semaine] W',
                columnFormat: 'dddd D',
                slotDuration: '00:30:00',
                slotEventOverlap: false,
                ignoreTimezone: false,
                slotLabelFormat: $locale.DATETIME_FORMATS.shortTime,
                allDaySlot: false,
                theme: false,
                defaultView: $scope.current_user.parametrage_cahier_de_textes.preferredView,
                editable: can_edit,
                eventDurationEditable: can_edit,
                eventStartEditable: can_edit,
                selectable: can_edit,
                selectHelper: true,
                weekends: $scope.current_user.parametrage_cahier_de_textes.affichage_week_ends,
                views: {
                    timetableWeek: {
                        type: 'agenda',
                        duration: { weeks: 1 },
                        buttonText: 'Emploi du temps',
                        displayEventTime: false
                    },
                    textbookWeek: {
                        type: 'list',
                        duration: { weeks: 1 },
                        buttonText: 'Liste'
                    }
                },
                viewRender: function (view, element) {
                    $scope.current_user.date = view.start;
                    $scope.c_est_les_vacances = Utils.sont_ce_les_vacances(view.start.week(), $scope.zone);
                    if (view.name !== $scope.current_user.parametrage_cahier_de_textes.preferredView) {
                        set_preferred_view(view.name);
                    }
                    retrieve_data(view.start.toDate(), view.end.toDate());
                },
                eventRender: function (event, element, view) {
                    var elt_fc_content = element.find('.fc-content');
                    if (!_(['ELV', 'TUT']).contains($scope.current_user.profil_actif.type)) {
                        if (event.temps_estime > 0) {
                            var class_couleur = '';
                            if (event.temps_estime < 4) {
                                class_couleur = ' label-success';
                            }
                            else if (event.temps_estime < 8) {
                                class_couleur = ' label-info';
                            }
                            else if (event.temps_estime < 12) {
                                class_couleur = ' label-warning';
                            }
                            else if (event.temps_estime <= 15) {
                                class_couleur = ' label-danger';
                            }
                            elt_fc_content.prepend("<div class=\"est-time est-time-" + event.temps_estime + " " + class_couleur + "\"></div>");
                        }
                    }
                    if (event.has_resources) {
                        elt_fc_content.prepend('<i class="glyphicon glyphicon-paperclip"></i>');
                    }
                    var elt_fc_content_title = element.find('.fc-list-item-title');
                    if (elt_fc_content_title.length > 0
                        && (!_(event.details.cours).isNull() || !_(event.details.devoirs).isEmpty())) {
                        var event_content_1 = elt_fc_content_title.html() + "\n              <br>\n<div class=\"col-md-6 sequence-pedagogique\">";
                        if (!_(event.details.cours).isNull()) {
                            event_content_1 += "\n              <fieldset>\n                <legend>S\u00E9quence p\u00E9dagogique</legend>\n                " + event.details.cours.contenu + "\n              </fieldset>";
                        }
                        event_content_1 += '</div>';
                        if (!_(event.details.devoirs).isEmpty()) {
                            event_content_1 += "<fieldset>\n< legend > Devoirs < /legend>";
                            event_content_1 += '<ul class="col-md-6 devoirs">';
                            _(event.details.devoirs).each(function (assignement) {
                                var additional_classes = $scope.current_user.profil_actif.type === 'ELV' ? (assignement.fait ? 'fait' : 'a-faire') : '';
                                event_content_1 += "  <li class=\"devoir type" + assignement.type_devoir_id + " " + additional_classes + "\">";
                                if ($scope.current_user.parametrage_cahier_de_textes.affichage_types_de_devoir) {
                                    event_content_1 += "    <span class=\"type\">" + assignement.type_devoir_description + "</span>";
                                }
                                if (assignement.temps_estime > 0) {
                                    event_content_1 += "    <span class=\"temps-estime\">" + assignement.temps_estime * 5 + " minutes</span>\n" + assignement.contenu + "\n                      </li>";
                                }
                            });
                            event_content_1 += "</ul>\n</fieldset>";
                        }
                        elt_fc_content_title.html(event_content_1);
                    }
                },
                eventClick: function (event) {
                    if (_(['ENS', 'DOC']).contains($scope.current_user.profil_actif.type) || $scope.current_user.profil_actif.admin) {
                        if (!popup_ouverte) {
                            CreneauxEmploiDuTemps.get({ id: event.details.creneau_emploi_du_temps_id })
                                .$promise
                                .then(function (creneau_selectionne) {
                                creneau_selectionne.dirty = false;
                                creneau_selectionne.en_creation = false;
                                creneau_selectionne.heure_debut = event.start;
                                creneau_selectionne.heure_fin = event.end;
                                creneau_selectionne.regroupement_id = event.details.regroupement_id;
                                $scope.current_user.get_actual_subjects()
                                    .then(function (actual_subjects) {
                                    PopupsCreneau.edition($scope.raw_data, actual_subjects, $scope.current_user.actual_groups, creneau_selectionne, event.details.cours, event.details.devoirs, popup_callback, popup_ouverte);
                                });
                            });
                        }
                    }
                    else {
                        if (!popup_ouverte && ((event.details.devoirs.length > 0) || (!_(event.details.cours).isNull() && _(event.details.cours).has('contenu')))) {
                            PopupsCreneau.display(event.matiere, event.details.cours, event.details.devoirs, popup_callback, popup_ouverte);
                        }
                    }
                },
                select: function (start, end, allDay) {
                    if ($scope.calendar.options.selectable && $scope.calendar.options.editable && $scope.selected_regroupements.length > 0) {
                        if (end - start === 1800000) {
                            end = moment(end).add(30, 'minutes').toDate();
                        }
                        if (!popup_ouverte) {
                            start = new Date(start);
                            end = new Date(end);
                            var regroupement_id_1 = $scope.selected_regroupements[0].id;
                            var new_creneau_1 = new CreneauxEmploiDuTemps({
                                regroupement_id: regroupement_id_1,
                                jour_de_la_semaine: start.getDay(),
                                heure_debut: moment(start).toISOString(),
                                heure_fin: moment(end).toISOString(),
                                matiere_id: ''
                            });
                            new_creneau_1.$save()
                                .then(function () {
                                new_creneau_1.dirty = true;
                                new_creneau_1.en_creation = true;
                                new_creneau_1.heure_debut = start;
                                new_creneau_1.heure_fin = end;
                                new_creneau_1.regroupement_id = regroupement_id_1;
                                $scope.current_user.get_actual_subjects()
                                    .then(function (actual_subjects) {
                                    PopupsCreneau.edition($scope.raw_data, actual_subjects, $scope.current_user.actual_groups, new_creneau_1, null, [], popup_callback, popup_ouverte);
                                });
                                $scope.emploi_du_temps.fullCalendar('unselect');
                            });
                        }
                    }
                },
                eventDrop: function (event, delta, revertFunc, jsEvent, ui, view) {
                    if ($scope.calendar.options.selectable && $scope.calendar.options.editable) {
                        CreneauxEmploiDuTemps.update({
                            id: event.details.creneau_emploi_du_temps_id,
                            heure_debut: event.start.toDate(),
                            heure_fin: event.end.toDate(),
                            jour_de_la_semaine: event.end.day()
                        });
                    }
                },
                eventResize: function (event, delta, revertFunc, jsEvent, ui, view) {
                    if ($scope.calendar.options.selectable && $scope.calendar.options.editable) {
                        CreneauxEmploiDuTemps.update({
                            id: event.details.creneau_emploi_du_temps_id,
                            heure_debut: event.start.toDate(),
                            heure_fin: event.end.toDate()
                        });
                    }
                }
            },
            events: []
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('RecursionHelper', ['$compile',
    function ($compile) {
        return {
            compile: function (element, link) {
                if (angular.isFunction(link)) {
                    link = { post: link };
                }
                var contents = element.contents().remove();
                var compiledContents;
                return {
                    pre: (link && link.pre) ? link.pre : null,
                    post: function (scope, element) {
                        if (!compiledContents) {
                            compiledContents = $compile(contents);
                        }
                        compiledContents(scope, function (clone) {
                            element.append(clone);
                        });
                        if (link && link.post) {
                            link.post.apply(null, arguments);
                        }
                    }
                };
            }
        };
    }])
    .directive('cartable', ['RecursionHelper',
    function (RecursionHelper) {
        return {
            scope: {
                racine: '=racine',
                target: '=target',
                regroupement: '=regroupement',
                addCallback: '=addCallback'
            },
            replace: true,
            controller: ['$scope', '$sce', 'URL_DOCS', 'Documents',
                function ($scope, $sce, URL_DOCS, Documents) {
                    var ctrl = $scope;
                    ctrl.$ctrl = ctrl;
                    ctrl.getChildren = function (noeud) {
                        Documents.list_files(noeud.hash).then(function (response) {
                            noeud.children = _(response.data.files).rest();
                        });
                    };
                    ctrl.add_ressource_to_target = function (target, node, regroupement) {
                        if (target.ressources === undefined) {
                            target.ressources = [];
                        }
                        if (_(target.ressources).findWhere({ hash: node.hash }) === undefined) {
                            Documents.ajout_au_cahier_de_textes(regroupement, node)
                                .then(ctrl.addCallback(target), function (response) {
                                console.debug(response.error);
                            });
                        }
                    };
                    ctrl.add_ressource_already_in_CT_to_target = function (target, node) {
                        target.ressources.push({
                            name: node.name,
                            hash: node.hash,
                            url: $sce.trustAsResourceUrl(URL_DOCS + "/api/connector?cmd=file&target=" + node.hash)
                        });
                    };
                }
            ],
            template: '<ul class="cartable">' +
                '                              <li ng:repeat="node in $ctrl.racine"' +
                '                          ng:class="{\'disabled\': node.name == \'Cahier de textes.ct\'}"' +
                '                          style="list-style-type: none">' +
                '                              <span class="glyphicon"' +
                '                          ng:class="{\'glyphicon-folder-open\': node.children, \'glyphicon-folder-close\': !node.children}"' +
                '                          ng:if="node.mime == \'directory\'"' +
                '                          ng:click="$ctrl.getChildren( node )">' +
                '        {{node.name}}' +
                '    </span>' +
                '    <button class="btn btn-sm btn-success from-docs"' +
                '            style="padding:top: 0; padding:bottom: 0"' +
                '            ng:if="node.mime != \'directory\'"' +
                '            ng:click="$ctrl.add_ressource_to_target( $ctrl.target, node, $ctrl.regroupement )">' +
                '      <span class="glyphicon glyphicon-plus"></span>' +
                '    </button>' +
                '    <button class="btn btn-sm btn-success from-ct"' +
                '            style="padding:top: 0; padding:bottom: 0"' +
                '            ng:if="node.mime != \'directory\'"' +
                '            ng:click="$ctrl.add_ressource_already_in_CT_to_target( $ctrl.target, node )">' +
                '      <span class="glyphicon glyphicon-plus"></span>' +
                '    </button>' +
                '    <span class="glyphicon glyphicon-file" ng:if="node.mime != \'directory\'">' +
                '        {{node.name}} <span ng:if="node.mime != \'directory\'">({{node.mime}})</span>' +
                '    </span>' +
                '    <div cartable' +
                '         ng:if="node.mime == \'directory\'"' +
                '         racine="node.children"' +
                '         target="$ctrl.target"' +
                '         regroupement="$ctrl.regroupement"' +
                '         add-callback="$ctrl.addCallback">' +
                '    </div>' +
                '  </li>' +
                '</ul>',
            compile: RecursionHelper.compile
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .directive('fileModel', ['$parse',
    function ($parse) {
        return {
            restrict: 'A',
            link: function (scope, element, attrs) {
                var model = $parse(attrs.fileModel);
                var modelSetter = model.assign;
                element.bind('change', function () {
                    scope.$apply(function () {
                        modelSetter(scope, element[0].files[0]);
                    });
                });
            }
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('Cours', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/cours/:id", { id: '@id' }, {
            update: { method: 'PUT' },
            valide: {
                method: 'PUT',
                url: APP_PATH + "/api/cours/:id/valide"
            },
            copie: {
                method: 'PUT',
                url: APP_PATH + "/api/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date",
                params: {
                    id: '@id',
                    regroupement_id: '@regroupement_id',
                    creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                    date: '@date'
                }
            }
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('CreneauxEmploiDuTemps', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/creneaux_emploi_du_temps/:id", {
            id: '@id',
            regroupement_id: '@regroupement_id',
            previous_regroupement_id: '@previous_regroupement_id',
            jour_de_la_semaine: '@jour_de_la_semaine',
            heure_debut: '@heure_debut',
            heure_fin: '@heure_fin',
            matiere_id: '@matiere_id',
            semainier_regroupement: '@semainier_regroupement',
            semainier_salle: '@semainier_salle'
        }, {
            update: { method: 'PUT' },
            delete: {
                method: 'DELETE',
                params: {
                    id: '@id',
                    date_creneau: '@date_creneau'
                }
            },
            bulk: {
                method: 'POST',
                isArray: true,
                url: APP_PATH + "/api/creneaux_emploi_du_temps/bulk",
                params: { creneaux_emploi_du_temps: '@creneaux_emploi_du_temps' }
            },
            bulk_delete: {
                method: 'DELETE',
                isArray: true,
                url: APP_PATH + "/api/creneaux_emploi_du_temps/bulk",
                params: {
                    ids: '@ids',
                    date_creneau: '@date_creneau'
                }
            }
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('Devoirs', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/devoirs/:id", {
            id: '@id',
            uid: '@uid'
        }, {
            update: { method: 'PUT' },
            fait: {
                method: 'PUT',
                url: APP_PATH + "/api/devoirs/:id/fait"
            },
            copie: {
                method: 'PUT',
                url: APP_PATH + "/api/devoirs/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due",
                params: {
                    id: '@id',
                    cours_id: '@cours_id',
                    creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                    date_due: '@date_due'
                }
            }
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('Etablissements', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/etablissements/:uai", { uai: '@uai' });
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('Matchable', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/matchables/:uai/:hash_item", {
            uai: '@uai',
            hash_item: '@hash_item',
            id_annuaire: '@id_annuaire'
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .factory('Salles', ['$resource', 'APP_PATH',
    function ($resource, APP_PATH) {
        return $resource(APP_PATH + "/api/salles/:id", { id: '@id' }, {
            bulk: {
                method: 'POST',
                isArray: true,
                url: APP_PATH + "/api/salles/bulk",
                params: { salles: '@salles' }
            }
        });
    }]);
angular.module('cahierDeTextesClientApp')
    .service('API', ['$http', 'APP_PATH', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs', 'Etablissements',
    function ($http, APP_PATH, CreneauxEmploiDuTemps, Cours, Devoirs, Etablissements) {
        this.get_etablissement = function (params) {
            return Etablissements.get(params);
        };
        this.query_statistiques_regroupements = function (uai) {
            return $http.get(APP_PATH + "/api/etablissements/" + uai + "/statistiques/regroupements");
        };
        this.query_types_de_devoir = _.memoize(function () {
            return $http.get(APP_PATH + "/api/types_de_devoir");
        });
        this.get_type_de_devoir = _.memoize(function (id) {
            return $http.get(APP_PATH + "/api/types_de_devoir/" + id);
        });
        this.get_emploi_du_temps = function (from, to, uai, uid) {
            return $http.get(APP_PATH + "/api/emplois_du_temps", {
                params: {
                    debut: from,
                    fin: to,
                    uai: uai,
                    uid: uid
                }
            });
        };
        this.get_creneau_emploi_du_temps = function (params) {
            return CreneauxEmploiDuTemps.get(params);
        };
        this.get_creneaux_emploi_du_temps_similaires = function (params) {
            return $http.get(APP_PATH + "/api/creneaux_emploi_du_temps/" + params.id + "/similaires", {
                params: {
                    debut: params.debut,
                    fin: params.fin
                }
            });
        };
        this.query_enseignants = function (uai) {
            return $http.get(APP_PATH + "/api/etablissements/" + uai + "/statistiques/enseignants");
        };
        this.get_enseignant = function (uai, enseignant_id) {
            return $http.get(APP_PATH + "/api/etablissements/" + uai + "/statistiques/enseignants/" + enseignant_id);
        };
        this.get_cours = function (params) {
            return Cours.get(params);
        };
        this.query_devoirs = function (params) {
            return Devoirs.query(params);
        };
        this.get_devoir = function (params) {
            return Devoirs.get(params);
        };
    }
]);
angular.module('cahierDeTextesClientApp')
    .service('Annuaire', ['$http', '$q', 'URL_ENT',
    function ($http, $q, URL_ENT) {
        var service = this;
        var beautify_group_type = function (type) {
            switch (type) {
                case 'CLS': return 'Classe';
                case 'GRP': return 'Groupe';
                case 'GPL': return 'Groupe libre';
                default: return '';
            }
        };
        service.query_subjects = _.memoize(function () {
            return $http.get(URL_ENT + "/api/subjects");
        });
        service.get_subject = _.memoize(function (matiere_id) {
            return $http.get(URL_ENT + "/api/subjects/" + matiere_id);
        });
        service.get_subjects = _.memoize(function (subjects_ids) {
            return $http.get(URL_ENT + "/api/subjects/", { params: { 'id[]': subjects_ids } });
        });
        service.get_structure = _.memoize(function (uai) {
            return $http.get(URL_ENT + "/api/structures/" + uai);
        });
        service.get_group = _.memoize(function (group_id) {
            return $http.get(URL_ENT + "/api/groups/" + group_id, { params: { expand: true } })
                .then(function success(response) {
                response.data.full_type = beautify_group_type(response.data.type);
                return $q.resolve(response);
            });
        });
        service.get_groups = _.memoize(function (groups_ids) {
            if (_(groups_ids).isEmpty()) {
                return $q.resolve({ data: [] });
            }
            else {
                return $http.get(URL_ENT + "/api/groups/", { params: { 'id[]': groups_ids } })
                    .then(function success(response) {
                    response.data = response.data.map(function (group) {
                        group.full_type = beautify_group_type(group.type);
                        return group;
                    });
                    return $q.resolve(response);
                });
            }
        });
        service.get_groups_of_structures = _.memoize(function (structures_ids) {
            return $http.get(URL_ENT + "/api/groups/", { params: { 'structure_id[]': structures_ids } })
                .then(function success(response) {
                response.data = response.data.map(function (group) {
                    group.full_type = beautify_group_type(group.type);
                    return group;
                });
                return $q.resolve(response);
            });
        });
        service.get_user = _.memoize(function (user_id) {
            return $http.get(URL_ENT + "/api/users/" + user_id)
                .then(function (response) {
                response.data.profil_actif = _(response.data.profiles).findWhere({ active: true });
                response.data.get_actual_groups = function () {
                    return service.get_groups(_(response.data.groups).pluck('group_id'))
                        .then(function (groups) {
                        return $q.resolve(groups.data);
                    });
                };
                response.data.get_actual_subjects = function () {
                    return service.get_subjects(_(response.data.groups).pluck('subject_id'))
                        .then(function (subjects) {
                        return $q.resolve(subjects.data);
                    });
                };
                return response;
            });
        });
        service.get_users = _.memoize(function (users_ids) {
            return $http.get(URL_ENT + "/api/users/", { params: { 'id[]': users_ids } });
        });
    }
]);
angular.module('cahierDeTextesClientApp')
    .service('Documents', ['$http', '$q', 'URL_DOCS', 'Annuaire',
    function ($http, $q, URL_DOCS, Annuaire) {
        var Documents = this;
        var cdt_folder_name = 'Cahier de textes.ct';
        Documents.list_files = _.memoize(function (root) {
            var params = {
                cmd: 'open',
                target: ''
            };
            if (root == undefined) {
                params.tree = 1;
            }
            else {
                params.target = root;
            }
            return $http.get(URL_DOCS + "/api/connector", { params: params });
        });
        Documents.mkdir = function (parent_hash, name) {
            var params = {
                cmd: 'mkdir',
                target: parent_hash,
                name: name
            };
            return $http.get(URL_DOCS + "/api/connector", { params: params });
        };
        Documents.rm = function (hashes) {
            if (!_(hashes).isEmpty()) {
                var params = {
                    cmd: 'rm',
                    'targets[]': hashes
                };
                return $http.get(URL_DOCS + "/api/connector", { params: params });
            }
            else {
                return $q.reject('nothing to do');
            }
        };
        Documents.get_ctxt_folder_hash = function (regroupement) {
            var structure, structure_root, regroupements_root, regroupement_root, cdt_root;
            var error_handler = function error(response) { return $q.reject(response); };
            switch (regroupement.type) {
                case 'CLS':
                case 'GRP':
                    return Annuaire.get_structure(regroupement.structure_id)
                        .then(function success(response) {
                        structure = response.data;
                        return Documents.list_files();
                    }, error_handler)
                        .then(function success(response) {
                        structure_root = _(response.data.files).findWhere({ phash: null, name: structure.name });
                        return Documents.list_files(structure_root.hash);
                    }, error_handler)
                        .then(function success(response) {
                        regroupements_root = _(response.data.files).findWhere({ phash: structure_root.hash, name: regroupement.type == 'CLS' ? 'classes' : 'groupes' });
                        return Documents.list_files(regroupements_root.hash);
                    }, error_handler)
                        .then(function success(response) {
                        regroupement_root = _(response.data.files).findWhere({ phash: regroupements_root.hash, name: regroupement.name });
                        return Documents.list_files(regroupement_root.hash);
                    }, error_handler)
                        .then(function success(response) {
                        cdt_root = _(response.data.files).findWhere({ phash: regroupement_root.hash, name: cdt_folder_name });
                        if (cdt_root == undefined) {
                            return Documents.mkdir(regroupement_root.hash, cdt_folder_name)
                                .then(function success(response) {
                                return response.data.added[0].hash;
                            }, error_handler);
                        }
                        else {
                            return cdt_root.hash;
                        }
                    }, error_handler);
                case 'GPL':
                    return Documents.list_files()
                        .then(function success(response) {
                        regroupement_root = _(response.data.files).findWhere({ phash: null, name: regroupement.name });
                        return Documents.list_files(regroupement_root.hash);
                    }, error_handler)
                        .then(function success(response) {
                        cdt_root = _(response.data.files).findWhere({ phash: regroupement_root.hash, name: cdt_folder_name });
                        if (cdt_root == undefined) {
                            return Documents.mkdir(regroupement_root.hash, cdt_folder_name)
                                .then(function success(response) {
                                return response.data.added[0].hash;
                            }, error_handler);
                        }
                        else {
                            return cdt_root.hash;
                        }
                    }, error_handler);
                default: console.log('unknown group type');
            }
        };
        Documents.ajout_au_cahier_de_textes = function (classe, node) {
            return Documents.get_ctxt_folder_hash(classe)
                .then(function (ctxt_folder_hash) {
                var params = {
                    cmd: 'paste',
                    'targets[]': node.hash,
                    'renames[]': node.name,
                    dst: ctxt_folder_hash,
                    cut: false
                };
                return $http.get(URL_DOCS + "/api/connector", { params: params });
            })
                .then(function success(response) {
                return response.data;
            });
        };
        Documents.upload_dans_cahier_de_textes = function (classe, fichiers) {
            return Documents.get_ctxt_folder_hash(classe)
                .then(function (ctxt_folder_hash) {
                return $q.all(_(fichiers).map(function (file) {
                    var form_data = new FormData();
                    form_data.append('cmd', 'upload');
                    form_data.append('target', ctxt_folder_hash);
                    form_data.append('upload[]', file);
                    form_data.append('renames[]', file.name);
                    return $http.post(URL_DOCS + "/api/connector", form_data, {
                        headers: { 'Content-Type': undefined },
                        transformRequest: angular.identity
                    });
                }))
                    .then(function (response) {
                    return response;
                });
            });
        };
    }
]);
angular.module('cahierDeTextesClientApp')
    .service('fileUpload', ['$http',
    function ($http) {
        this.uploadFileToUrl = function (file, uploadUrl, data) {
            var fd = new FormData();
            fd.append('file', file);
            _.chain(data).keys().each(function (key) {
                fd.append(key, data[key]);
            });
            return $http.post(uploadUrl, fd, {
                transformRequest: angular.identity,
                headers: { 'Content-Type': undefined }
            });
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .service('PopupsCreneau', ['$uibModal', 'toastr', 'POPUP_ACTIONS', 'APP_PATH',
    function ($uibModal, toastr, POPUP_ACTIONS, APP_PATH) {
        var open_modal = function (params, popup_callback, popup_ouverte) {
            popup_ouverte = true;
            $uibModal.open(params)
                .result.then(function (scope_popup) {
                _(scope_popup.actions_done).each(function (action) {
                    switch (action) {
                        case POPUP_ACTIONS.CANCELLED:
                            toastr.info('', 'Annulation.');
                            break;
                        case POPUP_ACTIONS.CRENEAU_DELETED:
                            toastr.info('', 'Créneau supprimé.');
                            break;
                        case POPUP_ACTIONS.CRENEAU_MODIFIED:
                            toastr.info('', 'Créneau mis à jour.');
                            break;
                        case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_CREATED:
                            toastr.success('', 'Séquence pédagogique créée.');
                            break;
                        case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_MODIFIED:
                            toastr.success('', 'Séquence pédagogique modifiée.');
                            break;
                        case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DUPLICATED:
                            break;
                        case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DELETED:
                            toastr.success('', 'Séquence pédagogique supprimée.');
                            break;
                        case POPUP_ACTIONS.DEVOIR_CREATED:
                            toastr.success('', 'Devoir créé.');
                            break;
                        case POPUP_ACTIONS.DEVOIR_MODIFIED:
                            toastr.success('', 'Devoir modifié.');
                            break;
                        case POPUP_ACTIONS.DEVOIR_DUPLICATED:
                            break;
                        case POPUP_ACTIONS.DEVOIR_DELETED:
                            toastr.success('', 'Devoir supprimé.');
                            break;
                    }
                });
                popup_callback(scope_popup);
            })
                .finally(function () {
                popup_ouverte = false;
            });
        };
        this.edition = function (raw_data, matieres, classes, creneau, cours, devoirs, popup_callback, popup_ouverte) {
            open_modal({
                templateUrl: APP_PATH + "/app/views/popup_edition.html",
                controller: 'PopupEditionCtrl',
                resolve: {
                    raw_data: function () { return raw_data; },
                    matieres: function () { return matieres; },
                    classes: function () { return classes; },
                    creneau: function () { return creneau; },
                    cours: function () { return cours; },
                    devoirs: function () { return devoirs; }
                },
                backdrop: 'static'
            }, popup_callback, popup_ouverte);
        };
        this.display = function (titre, cours, devoirs, popup_callback, popup_ouverte) {
            open_modal({
                templateUrl: APP_PATH + "/app/views/popup_display.html",
                controller: 'PopupDisplayCtrl',
                resolve: {
                    titre: function () { return titre; },
                    cours: function () { return cours; },
                    devoirs: function () { return devoirs; }
                },
                backdrop: 'static'
            }, popup_callback, popup_ouverte);
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .service('Redirection', ['$state', 'CurrentUser',
    function ($state, CurrentUser) {
        this.doorman = function (allowed_types) {
            CurrentUser.get().then(function (response) {
                if (_(allowed_types).size() === 0
                    || (_(allowed_types).indexOf(response.data.profil_actif.type) === -1
                        && !(response.data.profil_actif.admin))) {
                    var stateName = '404';
                    switch (response.data.profil_actif.type) {
                        case 'DIR':
                            stateName = 'enseignants';
                            break;
                        case 'ADM':
                        case 'EVS':
                        case 'ENS':
                        case 'DOC':
                        case 'TUT':
                        case 'ELV':
                            stateName = 'emploi_du_temps';
                            break;
                    }
                    $state.go(stateName, $state.params, { reload: true, inherit: true, notify: true });
                }
            });
        };
    }
]);
angular.module('cahierDeTextesClientApp')
    .service('Utils', ['$locale', 'moment', 'SEMAINES_VACANCES',
    function ($locale, moment, SEMAINES_VACANCES) {
        var _this = this;
        this.school_year_start = function () {
            var now = moment();
            var school_year_start = moment();
            if (now.month() + 1 > 8) {
                school_year_start.set('year', now.year());
            }
            else {
                school_year_start.set('year', now.year() - 1);
            }
            school_year_start.set('month', 8);
            school_year_start.set('date', 1);
            return school_year_start;
        };
        this.school_year_end = function () {
            var now = moment();
            var school_year_end = moment();
            if (now.month() + 1 > 8) {
                school_year_end.set('year', now.year() + 1);
            }
            else {
                school_year_end.set('year', now.year());
            }
            school_year_end.set('month', 6);
            school_year_end.set('date', 7);
            return school_year_end;
        };
        this.is_in_school_year = function (date) {
            date = moment(date);
            return date.isAfter(this.school_year_start()) && date.isBefore(this.school_year_end());
        };
        this.sont_ce_les_vacances = function (i_semaine, zone) {
            return SEMAINES_VACANCES[zone].indexOf(i_semaine) != -1;
        };
        this.what_month = function (n_week) {
            var now = moment();
            var year = now.year();
            if ((n_week < 36) && (now.month() > 7)) {
                year++;
            }
            else if (now.month() < 7) {
                year--;
            }
            return moment(year).isoWeek(n_week).month();
        };
        this.fix_semainier_pronote = function (semainier_pronote, date_debut_annee_scolaire) {
            var nb_week_in_year = 52;
            var bsemainier_pronote = parseInt(semainier_pronote).toString(2);
            bsemainier_pronote = _this.padStart(bsemainier_pronote, nb_week_in_year + 1, '0');
            bsemainier_pronote = bsemainier_pronote.substr(0, nb_week_in_year).split('').reverse().join('');
            var pivot = nb_week_in_year - moment(new Date(date_debut_annee_scolaire)).week();
            var bsemainier_laclasse = bsemainier_pronote.slice(pivot, nb_week_in_year) + bsemainier_pronote.substr(0, pivot);
            bsemainier_laclasse = bsemainier_laclasse.split('').reverse().join('');
            return parseInt(bsemainier_laclasse, 2);
        };
        this.overlay_semainier = function () {
            return _.chain(_.range(1, 52))
                .map(function (s) {
                return {
                    semaine: s,
                    mois: _this.what_month(s)
                };
            })
                .groupBy(function (s) { return s.mois; })
                .toArray()
                .map(function (semaines, i) {
                return {
                    index: i > 7 ? i - 8 : i + 4,
                    label: $locale.DATETIME_FORMATS.MONTH[i],
                    semaines: semaines
                };
            })
                .value();
        };
        this.groupByKey = function (array, key) {
            return _.chain(array).map(function (i) { return i[key]; }).object(array).value();
        };
        this.padEnd = function (string, target_length, filler) {
            if (string.length >= target_length) {
                return string;
            }
            else {
                var pad_1 = '';
                _((target_length - string.length) / filler.length).times(function () { pad_1 += filler; });
                return (string + pad_1).substr(0, target_length);
            }
        };
        this.padStart = function (string, target_length, filler) {
            if (string.length >= target_length) {
                return string;
            }
            else {
                var pad_2 = '';
                _((target_length - string.length) / filler.length).times(function () { pad_2 += filler; });
                return (pad_2 + string).substr(target_length * -1);
            }
        };
        this.libelleHeure_to_Moment = function (libelle) {
            var horaire = libelle.split(':').map(function (i) { return parseInt(i); });
            var utc_offset = (new Date()).getTimezoneOffset() / 60 * -1;
            var date = moment().set({
                hour: horaire[0] + utc_offset,
                minute: horaire[1],
                second: horaire[2]
            });
            return date;
        };
        this.fixnum_to_bitfield = function (fixnum) {
            var string = fixnum.toString(2);
            var padding = '';
            _(52 - string.length).times(function () { padding += '0'; });
            string = padding + string;
            return _(string.split('')
                .map(function (e) { return parseInt(e); })
                .reverse())
                .rest();
        };
        this.bitfield_to_fixnum = function (bitfield) {
            return parseInt(bitfield.reverse().join('') + "0", 2);
        };
    }
]);
angular.module('cahierDeTextesClientApp')
    .service('CurrentUser', ['$http', '$q', 'APP_PATH', 'Annuaire',
    function ($http, $q, APP_PATH, Annuaire) {
        this.get = _.memoize(function () {
            return $http.get(APP_PATH + "/api/users/current")
                .then(function (response) {
                _(response.data.profils).each(function (profil) {
                    profil.regroupements = _.chain(response.data.regroupements)
                        .filter(function (classe) { return classe.etablissement_code == profil.structure_id; })
                        .map(function (classe) {
                        return {
                            id: classe.id,
                            libelle: classe.name,
                            type: classe.type
                        };
                    })
                        .uniq(function (item) { return item.id; })
                        .reject(function (item) { return _.isUndefined(item.id); })
                        .value();
                });
                response.data.profil_actif = _(response.data.profils).findWhere({ active: true });
                response.data.profil_actif.admin = !_.chain(response.data.profils)
                    .findWhere({
                    structure_id: response.data.profil_actif.structure_id,
                    type: 'ADM'
                })
                    .isUndefined()
                    .value();
                if (response.data.enfants.length > 0) {
                    var promises = response.data.enfants.map(function (child) {
                        return Annuaire.get_user(child.child_id)
                            .then(function (user) {
                            child.enfant = user.data;
                        });
                    });
                    $q.all(promises).then(function () {
                        response.data.enfant_actif = response.data.enfants[0];
                    });
                }
                response.data.get_actual_groups = function () {
                    var groups_ids = _.chain(response.data.groups).pluck('group_id').uniq().value();
                    var promise = $q.resolve([]);
                    if (_(['EVS', 'DIR', 'ADM']).contains(response.data.profil_actif.type) || response.data.profil_actif.admin) {
                        promise = Annuaire.get_groups_of_structures([response.data.profil_actif.structure_id]);
                    }
                    else {
                        promise = Annuaire.get_groups(groups_ids);
                    }
                    return promise
                        .then(function (groups) {
                        response.data.actual_groups = _(groups.data).select(function (group) {
                            return (group.structure_id == response.data.profil_actif.structure_id) || (group.type == 'GPL');
                        });
                        return $q.resolve(response.data.actual_groups);
                    });
                };
                response.data.extract_subjects_ids = function () {
                    return _.chain(response.data.groups).pluck('subject_id').uniq().value();
                };
                response.data.get_actual_subjects = function () {
                    return Annuaire.get_subjects(response.data.extract_subjects_ids())
                        .then(function (subjects) {
                        response.data.actual_subjects = subjects.data;
                        return $q.resolve(response.data.actual_subjects);
                    });
                };
                response.data.is = function (type) {
                    return this.profil_actif.type == type;
                };
                return response;
            });
        });
        this.update_parameters = function (parametres) {
            return $http.put(APP_PATH + "/api/users/current/parametres", { parameters: JSON.stringify(parametres) });
        };
    }]);
angular.module('cahierDeTextesClientApp')
    .service('log', ['$http', '$state', 'APP_PATH', 'CurrentUser', 'URL_ENT',
    function ($http, $state, APP_PATH, CurrentUser, URL_ENT) {
        this.add = function (app, url, params) {
            CurrentUser.get()
                .then(function (response) {
                var user = response.data;
                $http.post(URL_ENT + "/api/logs", {
                    application_id: app,
                    user_id: user.id,
                    structure_id: user.profil_actif.structure_id,
                    profil_id: user.profil_actif.type,
                    url: (_(url).isNull() ? APP_PATH + $state.current.url : url).substr(0, 1023),
                    params: _(params).isNull() ? _($state.params).map(function (value, key) { return key + "=" + value; }).join('&') : params
                })
                    .then(function success() { }, function error() { });
            });
        };
    }
]);
