//set the focus on first element with minimum tabIndex that is > 0
function getFocusOnFirstElement(){
tabNextItem = $$('input').pluck("tabIndex").without(0).min();
               $A($$('input')).each(function(s){
               if(s.tabIndex == tabNextItem) {
                   s.focus();
               }
           });
}

var ViewOneHandler = Class.create({
	initialize: function(applet) {
             this.applet = applet;
             if (this.applet.isReady()){
                   // setTimeout("getFocusOnFirstElement();", 100);
                }
	},
         
	//sets the current display page to the page specified//
	setPage: function(page){
               // move to the desired page
		this.applet.setPage(page);
	},
         
	//position the scroll bar so that the highlighted area shows up almost in the centre of the screen 
        // with label if any, on its left and text above it are visible
        // so subtract 10% of height and 20% of width, to cover some area on the left and top of the actual area
	setXYScroll: function(x, y ){            
                 
             // convert x and y from float values to integer
             y = parseInt( y );
             x = parseInt( x );
             this.applet.setXYScroll( x ,  y );
	},
	
	//highlights a portion of the image present on the page specified 
        //with a translucent overlay, if 'highlight' = true  and for 'seconds' time
	highlightArea: function(page, x, y, width, height, highlight, seconds, id){
              width = width-x
            height =height-y
                 width = (width + (width * 0.2)) ;
                 if (height < 23.6){
                     height = 23.6;
                 }
                 var description = "[HIGHLIGHT]<P>PAGE=" + page + "<P>X=" + x + "<P>Y=" + y + "<P>WIDTH=" + width + "<P>HEIGHT=" + height + "<P><P>EDIT=1<P>LABEL=MyHighlight"+id+"<P>FILLCOLOR=255,255,0<P>TRANSPARENT=1<P>";
                this.applet.addAnnotation(description);
	},
         
	removeHighlight: function(){
                current_page = this.applet.getPage();
                if(current_page != ""){
                    this.applet.deleteAllAnnotations("highlight", current_page);
                }
	},
         
	 //This will set scale mode used to display a page
         //0: best fit
         //1: Fit-to-window-width
         //2: Fit-to-window-height
	setScale: function(scale){
		this.applet.setScale(scale);
	},
         
         // to get the X resolution of the Image. This will available only if provided in the IMage header
	 getXResolution: function() {
	        var xdpi = this.applet.getXResolution();
	        return xdpi;
	 },
        
         // to get the Y resolution of the Image. This will available only if provided in the IMage header
	 getYResolution: function() {
	        var ydpi = this.applet.getYResolution();	
		return ydpi;
	 },
	 
        // gets the width of the image in image pixels
         getImageWidth: function(){
             var  width = this.applet.getImageWidth();
             return width;
         },
         
         // gets the height of the image in image pixels
         getImageHeight: function(){
             var  height = this.applet.getImageHeight();
             return height;
         }
         
});

