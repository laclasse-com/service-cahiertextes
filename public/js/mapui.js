
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
    function _refresh(elt){
   }
    
    function error(m) {
      alert (m);
    }
    
    /************************************
        Top level functions
    ************************************/
    MapUi.prototype.version = function() {
      return this.VERSION;
    }
    
    MapUi.prototype.refresh = function() {   
      var output = "";
      if (this.template !== undefined) {
        // template mustache.
        //var o2 = eval($.parseJSON(this.dataSet));
        var t = {
                  jour_jj:"LU", matiere:"Maths"
                };
        this.dataSet = t;       
        output = Mustache.to_html(this.template, $.parseJSON(this.dataSet));
        console.log(output);

      } else {
        output = this.dataSet;
      }
      
      $(this.htmlElt).html(output);
     }
    
    MapUi.prototype.load = function(data) {
      if ( data == undefined ) {
       if ( !this.url ) return error('url should be set');
       var self = this;
       $.ajax({
      		url: this.url,
      		success: 
      		  function(result){ 
      		    self.dataSet = result;
      		    self.refresh();
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
        this.dataSet = data;
        this.refresh();
      }       
    }
    
    
    window.MapUi = MapUi;
    
}).call(this);
