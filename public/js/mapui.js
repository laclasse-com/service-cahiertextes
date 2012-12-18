
(function () {

    /************************************
        Constants
    *************************************/

    var mapui,        
        // check for nodeJS
        hasModule = (typeof module !== 'undefined' && module.exports);
                        
    /************************************
        Constructors
    ************************************/

    // mapUi prototype object
    function MapUi(config) {
        var cfg = eval(config);
        this.url       = ( cfg['url'] == undefined ) ? undefined : cfg['url']; 
        this.htmlElt   = ( cfg['html_elt'] == undefined) ? undefined : cfg['html_elt'];
        this.dataSet   = ( cfg['data'] == undefined ) ? undefined : cfg['data'];
        this.template  = ( cfg['row_template'] == undefined ) ? undefined : cfg['row_template'];
    }

    
    /************************************
        Helpers
    ************************************/
    function setDataSet(d) {
      $(this.htmlElt).attr("style", "color:blue;");
      this.dataSet = d;
    }
    
    function getDataSet(d) {
      return this.dataSet;
    } 
    
    function _refresh(){
      var elt = $(this.htmlElt);
      var val = getDataSet();
      elt.html(val);
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
          return this.VERSION;
      },
      
      //
      // Load method sending GET url to get some data
      //
      load : function (data) {
        var elt = $(this.htmlElt);
        if ( data == undefined ) {
         if ( !this.url ) return error('url should be set');
         $.ajax({
        		url: this.url,
        		success: 
        		  function(result){ 
        		    setDataSet(result);
        		    elt.html(getDataSet());
        		  },
            statusCode: {
              404: function() {
                error('The page "'+this.url+'" was not found.');
              },
              500: function() {
                error('The server has made boo ! \nPlease retry later...');
              }
            }
          });
        } 
        else { 
          setDataSet(data);
          elt.html(getDataSet());
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
