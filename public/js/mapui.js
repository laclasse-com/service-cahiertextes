/**
	Mapui.js est un ojet simple qui permet de mapper des éléments HTML, et de leur associer 
	des métodes :
	 - refresh() pour raffraichir les données
	 - load() pour charger les données à partir d'un web service
	 - ...
	@author PGL pgl@erasme.org
*/


/*
// constructor function
function MyClass () {
  var privateVariable; // private member only available within the constructor fn

  this.privilegedMethod = function () { // it can access private members
    //..
  };
}

// A 'static method', it's just like a normal function 
// it has no relation with any 'MyClass' object instance
MyClass.staticMethod = function () {};

MyClass.prototype.publicMethod = function () {
  // the 'this' keyword refers to the object instance
  // you can access only 'privileged' and 'public' members
};

var myObj = new MyClass(); // new object instance

myObj.publicMethod();
MyClass.staticMethod();

*/

(function (undefined) {

    /************************************
        Constants
    ************************************/

    var mapui,
        VERSION   = "0.0.1",
        urlWs     = undefined,
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
    function MapUi(url, elt, data, tpl) {
        urlWs     = url;
        eltUI     = elt;
        dataSet   = data;
        template  = tpl;
    }

    /************************************
        Helpers
    ************************************/
    
    function _refresh(){
      $(eltUI).html(getDataSet());
    }
    
    /************************************
        Top level functions
    ************************************/
    mapui = function (url, elt, data, tpl) {
      return new MapUi(url, elt, data, tpl);
    };
    
    mapui.fn = MapUi.prototype = {
      // Version 
      version : function () {
          return VERSION;
      },
      
      //
      // Load method sending GET url to get some data
      //
      load : function () {
        $.ajax({
      		url: urlWs,
      		success: 
      		  function(result){ 
      		    setDataSet(result);
      		    _refresh();
      		  }
        });
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