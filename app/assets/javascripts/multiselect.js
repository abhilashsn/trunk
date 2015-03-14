jQuery.noConflict();

jQuery(document).ready(function($){
    $(document).ready(function(){
        $("#facility_collc").multiselect().multiselectfilter();
    });

});

jQuery(document).ready(function($){
    $("#facility_mpi_search_type_facility").change(function () {
        var array_of_checked_values = $("select").multiselect("getChecked").map(function(){
            return this.value;
        }).get();
        
        if(array_of_checked_values.length ==0){
                        $('#facility_collc').empty()
            var client_id= $('#facil_client').val();
            var url = 'get_faiclity_ids'
            var parameters =  'client_id=' + client_id;
            var test = $.ajax(url, {
                method : 'get',
                data : parameters,
                success : function(result) {
                    var string_fac = result;
                    for(i=0;i<= string_fac.length;i++){
                        var val = string_fac[i].toString()
                        var stringVal = val.split(',')
                        $('#facility_collc').append('<option value="'+stringVal[1]+'">'+stringVal[0]+'</option>').multiselect('refresh');
                    }
                }
            })
        }
        $("#hidethis").css("display", "");

    })
})

jQuery(document).ready(function($){
    $("#facil_client").change(function () {
        $('#facility_collc').empty()
        var client_id= $('#facil_client').val();
        var url = 'get_faiclity_ids'
        var parameters =  'client_id=' + client_id;
        var test = $.ajax(url, {
            method : 'get',
            data : parameters,
            success : function(result) {
                var string_fac = result;
                for(i=0;i<= string_fac.length;i++){
                    var val = string_fac[i].toString()
                    var stringVal = val.split(',')
                    $('#facility_collc').append('<option value="'+stringVal[1]+'">'+stringVal[0]+'</option>').multiselect('refresh');
                }


            }
        })

    })
})

