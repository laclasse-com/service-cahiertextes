/**
	Mapui.js est un ojet simple qui permet de mapper des éléments HTML, et de leur associer 
	des métodes :
	 - refresh() pour raffraichir les données
	 - load() pour charger les données à partir d'un web service
	 - ...
	@author PGL pgl@erasme.org
*/
(function () {

    /************************************
        Constants
    ************************************/

    var mapui,
        VERSION   = "0.0.1",
        url       = undefined,
        eltUI     = undefined,
        dataSet   = undefined,
        template  = undefined,
        
        // check for nodeJS
        hasModule = (typeof module !== 'undefined' && module.exports),
        
        setDataSet = function (d) {
          dataSet = d;
        },
        
        getDataSet = function (d) {
          return dataSet;
        };
        
    /************************************
        Constructors
    ************************************/


    // mapUi prototype object
    function MapUi(config) {
        cfg = eval(config);
        
        url     = loadConf('url', undefined);
        eltUI     = loadConf('html_elt', 'debug');
        dataSet   = loadConf('data', undefined);
        template  = loadConf('row_template', undefined);
    }

    /************************************
        Helpers
    ************************************/
    function loadConf(p, defV) {
        return (cfg[p] == undefined) ? defV : cfg[p];
    }
    
    
    function _refresh(){
      $(eltUI).html(getDataSet());
    }
    
    function error(m) {
      alert (m);
    }
    /************************************
        Top level functions
    ************************************/
    var mapui = function (config) {
      return new MapUi(config);
    };
    
    mapui.fn = MapUi.prototype = {
      // Version 
      version : function () {
          return VERSION;
      },
      
      //
      // Load method sending GET url to get some data
      //
      load : function (data) {
        if ( data == undefined ) {
         if ( !url ) return error('url should be set');
         $.ajax({
        		url: url,
        		success: 
        		  function(result){ 
        		    setDataSet(result);
        		    _refresh();
        		  },
            statusCode: {
              404: function() {
                error('The page "'+url+'" was not found.');
              },
              500: function() {
                error('The server has made boo ! \nPlease retry later...');
              }
            }
          });
        } 
        else { 
          setDataSet(data);
          _refresh();
        }       
      },
      
      //
      // Refresh method freshing html element's content
      //
      refresh : function () {
        _refresh();
      }
    };

    /************************************
        Exposing MapUi
    ************************************/

    // CommonJS module is defined
    if (hasModule) {
        module.exports = mapui;
    }
    /*global ender:false */
    if (typeof ender === 'undefined') {
        // here, `this` means `window` in the browser, or `global` on the server
        // add `moment` as a global object via a string identifier,
        // for Closure Compiler "advanced" mode
        this['mapui'] = mapui;
    }
    /*global define:false */
    if (typeof define === "function" && define.amd) {
        define("mapui", [], function () {
            return mapui;
        });
    }
    
}).call(this);