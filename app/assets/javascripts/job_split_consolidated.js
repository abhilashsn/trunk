// ...
//= require 'application'
//= require 'jquery'
//= require 'jquery-ui'
//= require 'jquery.validate'
//= require 'jquery.multisortable'
//= require best_in_place.purr
//= require best_in_place


$.noConflict();
jQuery(document).ready(function(){

    // set the value of image_to drop down based on values of image_from and image_count
    function setImageTo(){
        count_from = null;
        selected_img_from = $('#image_from').val();
        image_to_options = $("#image_to > option");
        image_count = $('#image_count').val();
        image_to_options.each(function(i){
            if(selected_img_from == $(this).text()){
                count_from = i;
                return false;
            }
        });
        if(image_count != null && count_from != null)
            count_to = parseInt(count_from) + parseInt(image_count);
        if( count_to != null ){
            image_to_options.each(function(i){
                if((count_to - 1) == i){
                    $(this).attr("selected",true);
                    return false;
                }
            });
        }
    }

    // set the value of image_count drop down based on values of image_from and image_to
    function setImageCount(){
        count_from = null;
        count_to = null;
        selected_img_from = $('#image_from').val();
        selected_img_to = $('#image_to').val();
        image_to_options = $("#image_to > option");
        image_to_options.each(function(i){
            if(selected_img_from == $(this).text()){
                count_from = i;
            }
            if(selected_img_to == $(this).text()){
                count_to = i;
            }
            if(count_from != null && count_to != null){
                $('#image_count').val(parseInt(count_to) - parseInt(count_from) + 1);
                return false;
            }
        });
    }
    setImageList();
    form_listener();

    $(document).on( "blur", '#image_from', function(){
        setImageCount();
    } );
    $(document).on( "blur", '#image_to', function(){
        setImageCount();
    } );
    $(document).on( "blur", '#image_count', function(){
        setImageTo();
    } );
    $(document).on("click", '#selectAll', function(e){
        var table= $(e.target).closest('table');
        $('td input:checkbox',table).prop('checked',this.checked);
    });

    $.validator.addMethod(
        "micrFormat",
        function (value, element) {
            var check_number = $("#temp_job_check_number").val();
            if(parseInt(check_number) == 0)
                var isPaymentCheck = false;
            else
                isPaymentCheck = true;
            var client_name = $("#client_name").val();
            if(client_name.toUpperCase() == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER")
                var upmc_client = true;
            else
                upmc_client = false;
            if(isPaymentCheck && !upmc_client)
                return value.match(/[^0*]/);
            else
                return true;
        },
        "Please put atleast one non-zero digit."
        );

});

form_listener = function() {
    var isPaymentCheck = function() {
        var check_number = $("#temp_job_check_number").val();
        if(parseInt(check_number) == 0)
            return false;
        else
            return true;

    }
    var upmc_client = function() {
        var client_name = $("#client_name").val();
        if(client_name.toUpperCase() == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER")
            return true;
        else
            return false;
    }
    $('#temp_job_form').validate({
        rules: {
            "temp_job[account_number]": {
                required: {
                    depends: function(element) { 
                        return (isPaymentCheck && !upmc_client)
                    }
                },
                digits: true,
                minlength: 3,
                maxlength: 15,
                micrFormat: true
            },
            "temp_job[aba_number]": {
                required: {
                    depends: function(element) { 
                        return (isPaymentCheck && !upmc_client)
                    }
                },
                digits: true,
                minlength: 9,
                maxlength: 9,
                micrFormat: true
            },
            "temp_job[check_number]": {
                required: true,
                digits: true,
                minlength: 1
            },
            "temp_job[check_amount]": {
                required: true,
                number: true,
                minlength: 1
            }
        }
    });
}

var setImageList = function(){

    // serializes the image list UL based on the IDs of li elemts, in this format:  204,207,205,208,206
    $.fn.serial = function() {
        var array = [];
        var $elem = $('#imageList');
        $elem.each(function(i) {
            var menu = this.id;
            $('li', this).each(function(e) {
                array.push(this.id);
            });
        });
        return array.join(',');
    }

    // make image reorder div sortable
    $('#imageList').multisortable({
        stop: function (event, ui) {
            var data = $('.sortable').serial();
            data = "image_ids=["+ data +"]";
            // POST to server using $.post or $.ajax
            $.ajax({
                data: data,
                type: 'POST',
                url: relative_url_root()+'/admin/job/reorder_images',
                success:function(result){
                    var job_id = $('#job_id').val();
                    $("#create_temp_job").load(relative_url_root()+"/admin/temp_jobs/new", "job_id="+job_id, function(){
                        form_listener();
                    });
                }
            });
        }
    });
}
