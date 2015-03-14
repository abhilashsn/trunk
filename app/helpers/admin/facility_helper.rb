module Admin::FacilityHelper
  
  def op_config_select name, params, hsh, key, options={}
    if name =~ /\[(\d+)\]/
      supkey = $`
      subkey = $1
      selected_value = hsh[supkey].present? ? hsh[supkey][subkey] : ""
      select_tag name, options_for_select(params.select{|k| k.name==key}.map{|i| [i.value, i.value]}.insert(0, ""), selected_value), options
    else
      select_tag name, options_for_select(params.select{|k| k.name==key}.map{|i| [i.value, i.value]}.insert(0, ""),hsh[name]), options
    end
  end


  def other_output_select name, type, params, hsh, key, options={}
    if name =~ /\[(\d+)\]/
      supkey = $`
      subkey = $1
      selected_value = hsh[supkey].present? ? hsh[supkey][subkey] : ""
      select_tag "#{type}[#{name}]", options_for_select(params.select{|k| k.name==key}.map{|i| [i.value, i.value]}.insert(0, ""), selected_value), options
    else
      select_tag "#{type}[#{name}]", options_for_select(params.select{|k| k.name==key}.map{|i| [i.value, i.value]}.insert(0, ""),hsh[name]), options
    end
  end

  def add_editable_text_to_combo(id, text)
    text = escape_javascript(text)
    javascript_tag("$('##{id}').jecValue('#{text}')");
  end

  def inject_edit_to_segment(id)
    script = <<END
	  $('##{id}').jec();
    $('##{id}').change(function (event) {
		limit = $('##{id} option:selected').size();
    var selected_value = $('##{id} option:selected').val();
    if ((limit==2)&&(selected_value.charAt(0)=='[')){
       if ('#{id}' != 'nm182_segment_3'){
         alert("Invalid data selection.");
         $('##{id} option:selected').last().removeAttr('selected');
       }
    }
	 if (limit > 2){
			$('##{id} option:selected').last().removeAttr('selected');
			}
	   });
END
    javascript_tag(script);
  end

  def toggle_div(id)

    script = <<END
	$('##{id}_title').click(function ( event ) {
	$('##{id}_div').toggle(2000);
    });
END
    javascript_tag(script);
  end


  def get_options(options)
    static_text = ""
    if @selected_seg.to_s.include?("@")
      @selected_seg = @selected_seg.to_s.split("@")
      if @selected_seg[0].to_s.include?("]") and !@selected_seg[1].to_s.include?("]")
        @selected_seg.reverse!
      end
      unless @selected_seg[1].blank?
        if !options.include?(@selected_seg[1]) and !(@selected_seg[1].to_s.include?('['))
          options<<@selected_seg[1]
        end
      end
      if !(@selected_seg[0].to_s.include?('[') ) and !options.include?(@selected_seg[0])
        static_text = @selected_seg[0]
      end
    else
      if !options.include?(@selected_seg) and !(@selected_seg.to_s.include?('['))
        static_text = @selected_seg.to_s
      end
    end
    return options, static_text
  end

  def validations_for_default_account_number
    if @is_partner_bac
      validations = " validateData(id, 'Default A/c#')"
    else
      validations = "validateAlphanumericHyphenPeriodForwardSlash(id)"
    end
    validations
  end

  def validations_for_balance_record_account_number
    validations = "changeToCapital(id);"
   
    if @is_partner_bac
      validations += " validateData(id, '')"
    else
      validations += " validateBalanceRecordAccountNumber(id)"
    end
    validations
  end

  def validations_for_balance_record_patient_name
    validations = "changeToCapital(id);"
    if @is_partner_bac
      validations += " validateData(id, '')"
    else
      validations += " validatePatientNameField(id, $('details_patient_name_format_validation').checked)"
    end
    validations
  end
  
  def default_facility_values_for_output_setup_tab
    @visible_def_svc_date = "visibility:hidden;"
   @visible_multiple_service_lines = "style='visibility:hidden;'"
     @visible_oth_def_pat_name = "style='visibility:hidden;'"
    @visible_other_isa_06 = "visibility:hidden;"
    @visible_isa_06_other_pat_pay = "visibility:hidden;"
    @visible_pat_pay_div = "style='display:none;'"
    @visible_op_log = "visibility:hidden"
    @visible_ins_zip = "display:none;"
    @visible_ins_folder = "display:none;"
    @visible_pat_folder = "display:none;"
    @visible_pat_pay_zip = "display:none;"
    @visible_nextgen_zip = "display:none;"
    @visible_nextgen_folder = "display:none;"
    @facility_specific_pay_name = false
    @global_pay_name = true
    @facility_specific_pay_id = false
    @global_pay_id = true
  end

  def default_facility_values_for_grid_setup_tab
    @ref_code_mandatory_visible = "style='visibility:hidden;'"
    @doc_classification_mandatory_visible = "style='visibility:hidden;'"
    @same_doc_classificn_within_a_job_visible = "style='visibility:hidden;'"
    @disable_double_keying_for_837 = false
    @enable_double_keying_for_837 = true
    @disable_random_sampling = true
    @enable_random_sampling = false
  end

  def file_name_componets
    [["Client Id", "[Client Id]"],
      ["Batch date(MMDDYY)", "[Batch date(MMDDYY)]"],
      ["Batch date(CCYYMMDD)", "[Batch date(CCYYMMDD)]"],
      ["Batch date(MMDDCCYY)","[Batch date(MMDDCCYY)]"],
      ["Batch date(DDMMYY)", "[Batch date(DDMMYY)]"],
      ["Batch date(YYMMDD)", "[Batch date(YYMMDD)]"],
      ["Batch date(YMMDD)", "[Batch date(YMMDD)]"],
      ["Batch date(MMDD)","[Batch date(MMDD)]"],
      ["Facility Name abbreviation", "[Facility Abbr]"],
      ["Batch Id", "[Batch Id]"],
      ["3-SITE", "[3-SITE]"],
      ["Facility Name", "[Facility Name]"],
      ["Check Number", "[Check Num]"],
      ["Payer Name", "[Payer Name]"],
      ["Cut", "[Cut]"],
      ["EXT", "[EXT]"],
      ["ABA Routing Number", "[ABA Routing Num]"],
      ["Image File Name", "[Image File Name]"],
      ["Payer Account Number", "[Payer Account Num]"],
      ["Check Amount", "[Check Amount]"],
      ["Payer ID", "[Payer ID]"],
      ["Payer Group", "[Payer Group]"],
      ["Output Payid", "[Output Payid]"],
      ["Lockbox ID","[Lockbox ID]"]]
  end
end
