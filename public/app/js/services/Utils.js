'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service( 'Utils',
              [ '$locale', 'moment', 'SEMAINES_VACANCES',
                function( $locale, moment, SEMAINES_VACANCES ) {
                    var _this = this;
                    this.school_year_start = function() {
                        var now = moment();
                        var school_year_start = moment();

                        if ( now.month() + 1 > 8 ) {
                            school_year_start.set( 'year', now.year() );
                        } else {
                            school_year_start.set( 'year', now.year() - 1 );
                        }
                        school_year_start.set( 'month', 8 );
                        school_year_start.set( 'date', 1 );

                        return school_year_start;
                    };

                    this.school_year_end = function() {
                        var now = moment();
                        var school_year_end = moment();

                        if ( now.month() + 1 > 8 ) {
                            school_year_end.set( 'year', now.year() + 1 );
                        } else {
                            school_year_end.set( 'year', now.year() );
                        }
                        school_year_end.set( 'month', 6 );
                        school_year_end.set( 'date', 7 );

                        return school_year_end;
                    };

                    this.is_in_school_year = function( date ) {
                        date = moment( date );
                        return date.isAfter( this.school_year_start() ) && date.isBefore( this.school_year_end() );
                    };

                    this.sont_ce_les_vacances = function( i_semaine, zone ) {
                        return SEMAINES_VACANCES[ zone ].indexOf( i_semaine ) != -1;
                    };

                    this.what_month = function( n_week ) {
                        var now = moment();
                        var year = now.year();
                        if ( ( n_week < 36 ) && ( now.month() > 7 ) ) {
                            year++;
                        } else if ( now.month() < 7 ) {
                            year--;
                        }
                        return moment( year ).isoWeek( n_week ).month();
                    };

                    this.overlay_semainier = function() {
                        return _.chain( _.range(1, 52) )
                            .map( function( s ) { return { semaine: s,
                                                           mois: _this.what_month( s ) }; } )
                            .groupBy( function( s ) { return s.mois; } )
                            .toArray()
                            .map( function( semaines, i ) {
                                return { index: i > 7 ? i - 8 : i + 4,
                                         label: $locale.DATETIME_FORMATS.MONTH[ i ],
                                         semaines: semaines };
                            } )
                            .value();
                    };

                    this.groupByKey = function( array, key ) {
                        return _.chain( array ).map( function( i ) { return i[ key ]; } ).object( array ).value();
                    };

                    this.padEnd = function( string, target_length, filler ) {
                        if ( string.length >= target_length ) {
                            return string;
                        } else {
                            var pad = '';
                            _( (target_length - string.length) / filler.length ).times( function() { pad += filler; } );

                            return (string + pad).substr( 0, target_length );
                        }
                    };

                    this.padStart = function( string, target_length, filler ) {
                        if ( string.length >= target_length ) {
                            return string;
                        } else {
                            var pad = '';
                            _( (target_length - string.length) / filler.length ).times( function() { pad += filler; } );

                            return (pad + string).substr( target_length * -1 );
                        }
                    };

                }
              ] );
