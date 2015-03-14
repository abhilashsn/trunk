# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Make IE overlook calles to console API

unless window.console
  (->
    names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml", "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"]
    i = undefined
    l = names.length
    window.console = {}
    i = 0
    while i < l
      window.console[names[i]] = ->
      i++
  )()

jQuery ->
  Placeholders.init({live: true})

  jQuery.ajaxPrefilter (options, originalOptions, jqXHR) ->
    if options.spinner
      spinner = jQuery(options.spinner)
      if spinner and spinner.length > 0
        timeoutId = setTimeout(->
          spinner.spin()
        , 500)
        jqXHR.always ->
          clearTimeout timeoutId
          $("input:submit").button("reset")
          spinner.spin(false)

      else
        console.log "Found spinner parameter, but couldn't find the specified element."

 
  $('.amount').autoNumeric({aSep: ''})

  $("#claim_summary").on("click", "tr"
    (->
      $("div#claim_details_table").html($("div.claim_service#" + this.id + "_details").html())
      $('div#claim_details_table table').fixedHeaderTable({height: 200})
    ))

  $("#claim_summary").on("click", "input:radio"
    (->
      d = $(this).data()
      renderMpi(d.qaFlag, d.claimId, d.mpiStartTime, d.mpiFoundTime, d.mpiUsedTime, d.serviceLineCount, d.accountNumber, d.patientLastName, d.patientFirstName, d.dateOfServiceFrom, d.pageNo, d.claimLevelEob,d.job,d.mode, d.procStartTime)
    ))
  
  $("#mpi_search").submit ->
    btn = $("input:submit")
    btn.button("loading")
    $.ajaxSetup({async: true, spinner: "#main"})
    $.get(this.action, $(this).serialize(), null, 'script')
    $("div#claim_details_table").html("")
    $("tr.claim_summary").on("click", 
      (->
        $("div#claim_details_table").html($("div.claim_service#" + this.id).html())
      )
    )
    return false