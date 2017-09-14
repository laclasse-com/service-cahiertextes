'use strict';
angular.module( 'cahierDeTextesClientApp' )
  .run( [ '$templateCache',
    function( $templateCache ) {
      $templateCache.put( 'views/dashboard_teacher.html',
                          '<div class="panel panel-default">    <div class="panel-heading">        <div class="row">            <a class="btn btn-info pull-left" ui:sref="enseignants" ng:if="current_user.profil_actif.type === \'DIR\'" >← Retour à la liste des enseignants</a>        </div>    </div>    <div class="panel-body">        <h4 class="col-md-12 pull-left">{{enseignant.firstname}} {{enseignant.lastname}}</h4>        <div class="col-md-4">            <div class="panel panel-default">                <div class="panel-body">                    <legend ng:repeat="email in enseignant.emails">                        <span class="glyphicon glyphicon-envelope"></span>                        <a class="email" href="mailto:{{email.address}}"                           ng:style="{\'font-size\': email.primary ? \'inherit\' : \'75%\'}">{{email.address}}</a>                    </legend>                    <fieldset>                        <legend><span class="glyphicon glyphicon-briefcase"></span> Matières enseignées</legend>                        <span class="label label-primary pull-left" ng:repeat="matiere in enseignant.liste_matieres">{{matiere.name}}</span>                    </fieldset>                    <fieldset>                        <legend><span class="glyphicon glyphicon-envelope"></span> Classes et Groupes</legend>                        <span class="label pull-left"                              ng:class="{\'label-success\': regroupement.type === \'GRP\', \'label-info\': regroupement.type === \'CLS\', \'label-warning\': regroupement.type === \'GPL\' }"                              ng:repeat="regroupement in enseignant.liste_regroupements">{{regroupement.name}}</span>                    </fieldset>                    <fieldset ng:if="enseignant.prof_principal.length > 0">                        <legend><span class="glyphicon glyphicon-bell"></span> Professeur principal de</legend>                        <span class="label label-info pull-left" ng:repeat="regroupement in enseignant.prof_principal">{{regroupement.name}}</span>                    </fieldset>                </div>            </div>        </div>        <div class="col-md-8">            <div class="panel panel-default">                <div class="panel-body row">                    <nvd3 data="graphiques.pieChart.data" options="graphiques.pieChart.options"></nvd3>                    <nvd3 data="graphiques.multiBarChart.data" options="graphiques.multiBarChart.options"></nvd3>                </div>            </div>        </div>    </div></div><div class="panel panel-default">    <div class="panel-heading">        <div class="row">            <div class="col-md-9">                <div class="ui-select-wrapper">                    <ui-select multiple class="pull-left" theme="bootstrap"                               append-to-body="true"                               ng:if="enseignant.liste_regroupements.length > 0"                               ng:change="graphiques.populate( raw_data )"                               ng:model="scope.selected_regroupements">                        <ui-select-match placeholder="Regroupement(s)...">                            <span class="label" ng:class="{\'label-success\': $item.type === \'GRP\', \'label-info\': $item.type === \'CLS\', \'label-warning\': $item.type === \'GPL\' }">                                {{$item.name}}                            </span>                        </ui-select-match>                        <ui-select-choices repeat="regroupement in enseignant.liste_regroupements | orderBy:[\'type\',\'name\']"                                           group-by="\'full_type\'">                            {{regroupement.name}}                        </ui-select-choices>                    </ui-select>                    <button class="btn btn-xs btn-primary"                            ng:click="select_all_regroupements()"><span class="glyphicon glyphicon-certificate"></span></button>                    <button class="btn btn-xs btn-default"                            ng:click="select_no_regroupements()"><span class="glyphicon glyphicon-erase"></span></button>                </div>            </div>            <select class="col-md-3"                    ng:model="moisCourant"                    ng:change="graphiques.populate( raw_data )"                    ng:options="mois.indexOf(m)+1 as m for m in mois">                <option value="">Toute l\'année</option>            </select>        </div>        <label>            <checkbox class="btn-success"                      ng:model="scope.montre_valides"></checkbox>            afficher les saisies visées        </label>        <div class="clearfix"></div>    </div>    <div class="panel-body">        <table class="table">            <thead>                <tr>                    <th style="width:12em;">Date</th>                    <th style="width:12em;">Classe / Groupe</th>                    <th style="width:12em;">Matière</th>                    <th>Cours</th>                    <th>Travail à faire</th>                    <th>                        <button class="btn btn-warning pull-right"                                ng:class="{\'disabled\': nb_saisies_visables < 1 }"                                ng:if="current_user.profil_actif.type === \'DIR\'"                                ng:click="valide_all()">                            <span class="glyphicon glyphicon-check"></span> Viser la totalité                        </button>                    </th>                </tr>            </thead>            <tbody>                <tr ng:repeat="saisie in raw_data | filter:filter_saisie( montre_valides, moisCourant, selected_regroupements ) | orderBy:\'cours.date_cours\'"                    ng:class="{\'even\': $even, \'odd\': $odd, \'recent\': saisie.recent && current_user.profil_actif.type === \'DIR\' }">                    <td>{{saisie.cours.date_cours | amDateFormat:\'Do MMMM YYYY\'}}</td>                    <td ng:bind="saisie.group.name"></td>                    <td ng:bind="saisie.matiere.name"></td>                    <td>                        <div class="alert alert-default" ng:bind-html="saisie.cours.contenu"></div>                    </td>                    <td>                        <div class="alert alert-default" ng:repeat="devoir in saisie.devoirs" ng:bind-html="devoir.contenu"></div>                    </td>                    <td>                        <span switch                              class="violet"                              disabled="current_user.profil_actif.type !== \'DIR\' || saisie.recent"                              ng:disabled="current_user.profil_actif.type !== \'DIR\' || saisie.recent"                              ng:model="saisie.valide"                              ng:change="current_user.profil_actif.type === \'DIR\' && !saisie.recent && valide( saisie )" >                        </span>                    </td>                </tr>            </tbody>        </table>    </div></div>' );     } ] );