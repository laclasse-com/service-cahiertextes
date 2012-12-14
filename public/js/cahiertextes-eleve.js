/**
	
	@file cahiertextes-eleve.js
	@author PGL pgl@erasme.org
	@description : Ressources Javascripts pour les vues du cahier de textes
**/

;$(document).ready(function(){
  //
  // Mapping des éléments de l'interface
  //
  var TABS        = $('#nav-jours-eleve li');
  var TAF         = $('#controles-liste-eleve a#taf');
  var COURS       = $('#controles-liste-eleve a#cours');
  var AUJOURDHUI  = $('#controles-liste-eleve a#aujourdhui');
  var HIER        = $('#controles-liste-eleve a#hier');
  var DEMAIN      = $('#controles-liste-eleve a#demain');
  var PERIODE     = $('#controles-liste-eleve div#periode-eleve');
  var PARAMS      = $('#controles-liste-eleve a#params');
  var BADGES      = $('#nav-jours-eleve a .badge');
  var CONTENUS    = $('#liste-eleve div.contenu-jour-eleve');
  
  moment.lang('fr');
  var M =  moment(new Date());
  
  //
  // Initialisation
  //
  function initialize() {
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
    $('#nav-jours-eleve li.' + j).addClass("active");
    // Sélectionner le div de contenu corespondant
    $('#liste-eleve div.' + j).show();
  }
  
  function cacherToutLesTab(){
    // déselectionner tous les onglets
    TABS.removeClass('active');
    // Cacher tous les contenus
    CONTENUS.hide();
  }
  
  // Mettre à jour la période dans la barre de contrôle.
  function setPeriode() {
    first = M.day(1).format('dddd D');
    last  = M.day(5).format('dddd D');
    mois  = M.format('MMMM');
    PERIODE.html('Semaine du ' + first + ' au ' + last + ' ' + mois);
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
    initialize();
  });
  
  //
  // Prise en compte du clique sur "hier"
  //
  HIER.on('click', function () {
    alert ('hier');
  });
  
  //
  // Prise en compte du clique sur "demain"
  //
  DEMAIN.on('click', function () {
    alert ('demain');
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
