/**
	
	@file cahiertextes-eleve.js
	@author PGL pgl@erasme.org
	@description : Ressources Javascripts pour les vues du cahier de textes
**/

;$(document).ready(function(){
  //
  // Initialisation
  //
  function initialize() {
    // Cacher les badges
    $('#nav-jours-eleve a .badge').hide();
    // cacher tous les onglets
    cacherToutLesTab();
    // Activer l'onglet d'aujourd'hui
    ActiverJour(getAujourdhui());
  }
  
  function getAujourdhui(){
    var j = new Array("DI", "LU", "MA", "ME", "JE", "VE", "SA");
    var aujourdhui = new Date();
    return j[aujourdhui.getDay()];
  }
  
  function ActiverJour(j){
    // Sélectionner celui cliqué
    $('#nav-jours-eleve li.' + j).addClass("active");
    // Sélectionner le div de contenu corespondant
    $('#liste-eleve div.' + j).show();
  }
  
  function cacherToutLesTab(){
    // déselectionner tous les onglets
    $('#nav-jours-eleve li').removeClass('active');
    // Cacher tous les contenus
    $('#liste-eleve div.contenu-jour-eleve').hide();
  }
  
  //
  // Prise en compte de la sélection d'un jour sur la tab nav.
  //
  $('#nav-jours-eleve li').on('click', function () {
    var j = $(this).attr("class"); 
    cacherToutLesTab();
    ActiverJour(j);
  });
  
  //
  // Prise en compte du clique sur "taf"
  //
  $('#controles-liste-eleve a#taf').on('click', function () {
    alert ('taf');
  });
  
  //
  // Prise en compte du clique sur "cours"
  //
  $('#controles-liste-eleve a#cours').on('click', function () {
    alert ('cours');
  });
  
  //
  // Prise en compte du clique sur "aujourd'hui"
  //
  $('#controles-liste-eleve a#aujourdhui').on('click', function () {
    alert ('aujourdhui');
  });
  
  //
  // Prise en compte du clique sur "hier"
  //
  $('#controles-liste-eleve a#hier').on('click', function () {
    alert ('hier');
  });
  
  //
  // Prise en compte du clique sur "demain"
  //
  $('#controles-liste-eleve a#demain').on('click', function () {
    alert ('demain');
  });
  
  //
  // Prise en compte du clique sur "parametres"
  //
  $('#controles-liste-eleve a#params').on('click', function () {
    alert ('params');
  });
  

  initialize();
});
