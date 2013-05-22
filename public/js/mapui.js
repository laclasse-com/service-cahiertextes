
(function () {

    /************************************
        Constants
    *************************************/

    var hasModule = (typeof module !== 'undefined' && module.exports);
                        
    /************************************
        Constructors
    ************************************/

    // mapUi prototype object
    function MapUi(config) {
        var cfg = eval(config);
        this.url       = ( cfg['url'] == undefined ) ? undefined : cfg['url']; 
        this.htmlElt   = ( cfg['html_elt'] == undefined) ? undefined : cfg['html_elt'];
        this.dataSet   = ( cfg['data'] == undefined ) ? undefined : cfg['data'];
        this.template  = ( cfg['template'] == undefined ) ? undefined : cfg['template'];
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
      var tpl = "";  
      var self = this;
      if (this.template !== undefined || this.template !== '') {
        // template mustache.
        output = (Mustache.render(self.template, $.parseJSON(this.dataSet)));
        
        /*
        // chargement du template 
        $.get('./js/templates/' + self.template + '.html', function(result) {
          // Fetch the <script /> block from the loaded external
          // template file which contains our greetings template.
          var tpl = $(result).filter('script#'+self.template).html(self.template);
          output = (Mustache.render(tpl, $.parseJSON(this.dataSet)));
          $(this.htmlElt).html(output);
          alert(output);
        });
        */
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
      		url: self.url,
      		/*
      		success: 
      		  function(result){ 
      		    self.dataSet = result;
      		    self.refresh();
      		  },
      		*/
          statusCode: {
            404: function() {
              error('The page "'+self.url+'" was not found.');
            },
            500: function() {
              error('The server has made boo ! \nPlease retry later...');
            }
          }
        }).done(function (result) {
            //self.refresh();
            self.dataSet = eval("{ rows : " + result + " }");
            console.log(self.dataSet);
            //self.dataSet = $.parseJSON("{rows: [" + result + "] }");
            o = Mustache.to_html(self.template, $.parseJSON(self.dataSet));
            console.log(o);
            $('#debug').html(o);
          });
      } 
      else { 
        this.dataSet = data;
        this.refresh();
      }       
    }
    
    
    window.MapUi = MapUi;
    
}).call(this);
