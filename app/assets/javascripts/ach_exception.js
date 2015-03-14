//= require jquery
//= require jquery_ujs


//This allows AJAX searching on the ACH Approval page
$(function() {
  //alert("Yes it is working");
  $("#facilities .pagination a").live("click", function() {
    $.getScript(this.href);
    return false;
  });
  $('#facilities_search input').keyup(function () {
    var tempF = $('<input type="hidden" name="site_search_button" />').val("Search").appendTo(this);
    $.get($("#facilities_search").attr("action"), $("#facilities_search").serialize(), null, 'script');
    tempF.remove();
    return false;
  });
  $("#payers .pagination a").live("click", function() {
    $.getScript(this.href);
    return false;
  });
  $('#payers_search input').keyup(function () {
    var tempP = $('<input type="hidden" name="payer_search_button" />').val("Search").appendTo(this);
    $.get($("#payers_search").attr("action"), $("#payers_search").serialize(), null, 'script');
    tempP.remove();
    return false;
  });
 // $("#facilities_search input").keyup(function() {
 //   $.get($("#facilities_search").attr("action"), $("#facilities_search").serialize(), null, "script");
 //   return false;
 // });
});
