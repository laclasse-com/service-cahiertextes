/**
	
	@file cahiertextes.js
	@author PGL pgl@erasme.org
	@description : Ressources Javascripts pour les vues du cahier de textes
**/

;$(document).ready(function(){

  //
  // Prise en compte de la sélection d'un jour sur la tab nav.
  //
  $('#nav-jours-eleve a').on('click', function () {
    var s = $(this).html().substring(0,2).toUpperCase();   
    // déselectionner tous les onglets
    $('#nav-jours-eleve li').removeClass('active');
    // Cacher tous les contenus
    $('#liste-eleve div.contenu-jour-eleve').hide();
    
    // Sélectionner celui cliqué
    $(this).parents().addClass("active");
    // Sélectionner le div de contenu corespondant
    $('#liste-eleve div#'+ s).show();
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
  
});

