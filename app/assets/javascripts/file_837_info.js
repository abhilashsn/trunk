//= require jquery
//= require jquery_ujs
//= require best_in_place
//= require jquery.purr

$(document).ready(function(){
  /* Activating Best In Place */
  $(".best_in_place").best_in_place();

  $("tbody").each(function(index){
    $(this).hover(function() {
      $('#deleted_' + $(this).attr("id")).show();
    }, function() {
      $('#deleted_' + $(this).attr("id")).hide();
    });
  });
});

