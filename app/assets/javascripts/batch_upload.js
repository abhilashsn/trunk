function getInboundFiles(){
    var date = jQuery("#batch_date").val();
    var facility = jQuery('select#facility_name option:selected').val();
    if (facility == null || facility == 'Select'){
        alert('Please select a facility');
        return false;
    }
    jQuery('#inbound_id').val(null);
    jQuery.ajax({
      url: relative_url_root() +"/admin/batch_upload/get_inbound_records",
      data: {date : date, facility_name : facility},
      dataType: "json",
      success: function(result){
          jQuery('#inbound_details').html('');
          jQuery.each(result, function(index, value){
              if(index == 0){
                jQuery('#inbound_details').html(
                '<th width="200px">Inbound File ID</th>\n\
                <th width="200px">File Name</th>\n\
                <th width="200px">Arrival Time</th><th></th>');
              }
             jQuery('#inbound_details').append('<tr>\n\
            <td style="text-align:center;vertical-align:middle">'+value[0]+'</td>\n\
            <td style="text-align:center;vertical-align:middle">'+value[1]+'</td>\n\
            <td style="text-align:center;vertical-align:middle"">'+value[2]+'</td>\n\
            <td><input type="checkbox" id="inbound_record_'+value[0]+'" onclick="setInboundFileId('+value[0]+')"></td></tr>')
          });
      }
    });
}

function setInboundFileId(inboundId){
  jQuery('#inbound_id').val(inboundId);
  jQuery('#inbound_details').find('input[type=checkbox]').each(function(n){
      var inboundRowId = jQuery(this).attr('id');
      if(inboundRowId != 'inbound_record_'+inboundId+''){
          jQuery(this).removeAttr('checked');
      }
  });
}