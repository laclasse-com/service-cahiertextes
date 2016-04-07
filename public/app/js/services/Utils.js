'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service( 'Utils',
              [ 'moment',
                function( moment ) {
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
                }
              ] );
