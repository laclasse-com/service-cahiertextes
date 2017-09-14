'use strict';
angular.module( 'cahierDeTextesClientApp' )
  .run( [ '$templateCache',
    function( $templateCache ) {
      $templateCache.put( 'views/404.html',
                          '<em>Votre profil actuel ne vous permet pas d\'accéder au Cahier de Textes.</em>' );     } ] );