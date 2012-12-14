/**
	
	@file cahiertextes-eleve.js
	@author PGL pgl@erasme.org
	@description : Ressources Javascripts pour les vues du cahier de textes
**/

;$(document).ready(function(){
  //
  // Mapping des éléments de l'interface
  //
  var tabsSelector= '#nav-jours-eleve li';
  var TABS        = $(tabsSelector);                                // Tous les onglets, 1 par jour de la semaine
  var BADGES      = $('#nav-jours-eleve a .badge'); 
  var div_contenu = '#liste-eleve';                                 // Tous les badges affichant les devoirs à faire pour chaque onglet
  var CONTENUS    = $(div_contenu + ' div.contenu-jour-eleve');     // Tous les div affichant la liste des devoirs pour chaque jour

  var TAF         = $('#controles-liste-eleve a#taf');              // Bouton "Travail à faire"
  var COURS       = $('#controles-liste-eleve a#cours');            // Bouton "Cours"
  var AUJOURDHUI  = $('#controles-liste-eleve a#aujourdhui');       // Bouton "Aujourdhui"
  var LW          = $('#controles-liste-eleve a#lastweek');         // Bouton "Semaine dernière"
  var NW          = $('#controles-liste-eleve a#nextweek');         // Bouton "Semaine prochaine"
  var PARAMS      = $('#controles-liste-eleve a#params');           // Bouton "Paramètres"
  var PERIODE     = $('#controles-liste-eleve div#periode-eleve');  // Label affichant la semaine en cours
  
  moment.lang('fr');
  var M =  null;
  
  //
  // Initialisation
  //
  function initialize() {
    var Jour = ( M == undefined ) ? new Date() : M ;
    M = moment(Jour);
    // Cacher les badges
    BADGES.hide();
    // cacher tous les onglets
    cacherToutLesTab();
    // 
    setPeriode();
    // Activer l'onglet d'aujourd'hui
    ActiverJour(getAujourdhui());
  }
  
  // Renvoie le jour d'aujourd'hui sur 2 caractères
  function getAujourdhui(){
    return M.format('dd').toUpperCase();
  }
  
  //
  function ActiverJour(j){
    // Sélectionner celui cliqué
    $(tabsSelector + '.' + j).addClass("active");
    // Sélectionner le div de contenu corespondant
    $(div_contenu + ' div.' + j).show();
  }
  
  function cacherToutLesTab(){
    // déselectionner tous les onglets
    TABS.removeClass('active');
    // Cacher tous les contenus
    CONTENUS.hide();
  }
  
  // Mettre à jour la période dans la barre de contrôle.
  function setPeriode() {
    first = M.day(1).format('dddd D MMMM YYYY');
    last  = M.day(5).format('dddd D MMMM YYYY');
    PERIODE.html('Du ' + first + ' au ' + last);
  }
  
  //
  // Prise en compte de la sélection d'un jour sur la tab nav.
  //
  TABS.on('click', function () {
    var j = $(this).attr("class"); 
    cacherToutLesTab();
    ActiverJour(j);
  });

  //
  // Prise en compte du clique sur "taf"
  //
  TAF.on('click', function () {
    alert ('taf');
  });
  
  //
  // Prise en compte du clique sur "cours"
  //
  COURS.on('click', function () {
    alert ('cours');
  });
  
  //
  // Prise en compte du clique sur "aujourd'hui"
  //
  AUJOURDHUI.on('click', function () {
    M = moment(new Date());
    initialize();
  });
  
  //
  // Prise en compte du clique sur "hier"
  //
  LW.on('click', function () {
    M.add('w', -1);
    initialize();
  });
  
  //
  // Prise en compte du clique sur "demain"
  //
  NW.on('click', function () {
    M.add('w', 1);
    initialize();
  });
  
  //
  // Prise en compte du clique sur "parametres"
  //
  PARAMS.on('click', function () {
    alert ('params');
  });
  
  // Allez hop, init et c'est parti.
  initialize();

});