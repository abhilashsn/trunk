function getthewindow(){
		if($("insurance").value==0){
			populatePayerInfo('payer_popup');
		}
	   }
 //This will return the sub-uri if any
 function relative_url_root() {
		return "<%= @app_root -%>"
		}
Event.observe(window, 'load', function() {
// set the tab index of all elements with class as 'imported' to a very high number, 
// so that the user tabs thru them in the very end
    $$(".imported").each(
                    function(item) {
                   item.tabIndex = '800';
                   item.observe('change', function() {   
                                 item.className = "ocr_data edited";
                                  });
                    });
//set the tab index of all elements with class as 'certain' to a very high number, 
// so that the user tabs thru them in the very end
  $$(".certain").each(
                  function(item) {
                  item.tabIndex = '800';
                  item.observe('change', function() {   
                                 item.className = "ocr_data edited";
                                  });
                  }); 
   $$(".uncertain").each(
                  function(item) {
                  item.observe('change', function() {   
                                 item.className = "ocr_data edited";
                                  });
                   }); 
 //extract the coordinates and page attributes from each element and highlight corresponding area in the image                                                       
   count = 0;
 $$(".ocr_data").each(
                   // in OCR mode, set the tabIndex of MPI search button to zero
                  function(item) {
                        if (item.id == 'patient_account_id'){
                             $('mpi_button').tabIndex = '0';
                        }
                        myHandler = new ViewOneHandler(parent.document.getElementById("viewONE"));  
                          item.observe('focus', function(event) {
                                  element = event.findElement();
                                  coordinates = element.getAttribute('coordinates');
                                  var x, y;
                                  if(coordinates != null )
                                  {
                                      var coordinates_array = coordinates.split(',');
                                      x = parseFloat(coordinates_array[0]);
                                      y = parseFloat(coordinates_array[1]);
                                      width = parseFloat(coordinates_array[2]);
                                      height = parseFloat(coordinates_array[3]);
                                      page = parseFloat(element.getAttribute('page'));
                                      if((page !="") && (page !=null))
                                      {
                                          if( x != 0 && y != 0 && page != null) 
                                          {                                          
                                            myHandler.setPage(page);
                                            myHandler.highlightArea( page, x, y, width, height, true, -1, count++);
                                            //adjust the position of the scroll bar to show the highlighted area  
                                            image_height = myHandler.getImageHeight();
                                             image_width = myHandler.getImageWidth();                                            
                                             y = ( y - (image_height * 0.1));
                                             x = ( x - (image_width * 0.2));
                                            myHandler.setXYScroll( x , y );
                                          }   
                                      }
                                 }
                          }); 
                          item.observe('blur', function(){
                          myHandler.removeHighlight();
                          });
                          item.observe('mouseover', function(event) {
                                        element = event.findElement();
                                        var classNames = element.className.split(' ');
                                        for( var i=0; i<classNames.length; i++)
                                        {
                                        switch (classNames[i] ) {
                                              case "imported":
                                              element.title = "Imported from 837 or Index File"
                                              break
                                              case "certain":
                                              element.title = "OCR Certain"
                                              break
                                              case "uncertain":
                                              element.title = "OCR Uncertain"
                                              break
                                              case "edited":
                                              element.title = "OCR data edited by user"
                                              break
                                              default:
                                              element.title = "Not read by OCR"
                                              }
                                       }
                                
                          });
                         if (item.id == 'checkdate_id' && (item.getAttribute('coordinates') != null)){                               
                               setTimeout("$('checkdate_id').focus();", 100);
                        }
                  }
          );

          $$('input').each(function(item){		
		// When the user tabs out of an element, 
		// "remember" the element id by storing it in a js global variable		
		item.observe("blur", function() {
		setUserLocation(item.readAttribute('id'));		
		});
		item.observe('focus', function() {
		setUserLocation("");		
		});
		
		// If the user focuses on an element with tabIndex 0
		// by using a mouse click, force the next tabbing 
		// into the next available element with tabIndex > 0		
		if (item.tabIndex==0)
		  {
		      item.observe("blur", function(event) {				
			      nextElements = $$('input').slice($$('input').pluck('id').indexOf(item.id));
			      tabNextItem = nextElements.pluck("tabIndex").without(0).min();
				   return nextElements.find(function(sibling){
						if(sibling.tabIndex == tabNextItem) {
						  sibling.focus();
						  return;
						}
			      });
		  });     
		  }
          });
	});
