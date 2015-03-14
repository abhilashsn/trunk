# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Arguments
  #   - pages collection (generated from the model)
  #   - current controller (for proper page linking)
  #   - current page (got from params)
  def create_pagination(pages,controller,current_page)
    pagination = ""
    params[:controller] = controller 
    current_page = 1 if current_page.nil? 
    if pages.length > 1
      pagination << link_to('&lt;', {:params => params.merge('page' => pages.first)}) << " " 
    end 
    if pages.length > 1 
      pages.each do |page| 
        if (page.number < current_page.to_i+6) && (page.number > current_page.to_i-6)
          if current_page.to_i == page.number 
            pagination << page.number.to_s << " "
          else
            pagination << link_to(page.number, {:params => params.merge('page' => page)}) << " "
          end
        end 
      end 
    end
    if pages.length > 1
      pagination << link_to('&gt;', {:params => params.merge('page' => pages.last)}) << " " 
    end
    return pagination
  end
  
  def format_date(date)
    date.strftime('%m/%d') if date
  end
  
  def format_datetime(datetime, frmt="%m/%d/%y %H:%M")
    if datetime
      if datetime.is_a?(String)
        format_datetime(Time.parse(datetime), frmt)
      else
        datetime.strftime(frmt)
      end
    end
  end
  
  def format_complete_date(datetime)
    datetime.strftime('%m/%d/%Y %H:%M')
  end
  
  def format_complete_date_and_time(datetime)
    datetime.strftime('%m/%d/%Y %H:%M:%S')
  end
  
  def format_complete_date_without_century(datetime)
    if datetime
      datetime.strftime('%m/%d/%y %H:%M')
    end
  end
  
  def format_percentage(percent)
    unless percent.blank?
      formatted_percentage = sprintf("%0.2f", percent)
      if formatted_percentage.to_f >= 100.0 or formatted_percentage.to_f <= 0.0
        percent.to_i
      else
        formatted_percentage
      end
    end
  end
  
  def show_legend(hash)
    result = "<div id='legend'><dl>"
    hash.each do |color,text|
      result << "<dt class='#{color}'></dt><dd>#{text}</dd>"
    end
    result << "</dl></div>"
    result.html_safe 
  end

  # Helpers for sorting
  def sort_td_class_helper(my_param)
    result = ' <img src="/assets/arrowup.png"/>' if params[:sort] == my_param
    result = ' <img src="/assets/arrowdown.png"/>' if params[:sort] == my_param + "_reverse"
    return result
  end
  
  def sort_link_helper(text, param, controller, action)
    key = param
    key += "_reverse" if params[:sort] == param
    params[:controller] = controller

    options = { 
      :url => {:action => action, :params => params.merge({:sort => key, :page => params[:page]})},
      :update => 'table',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
    }   

    html_options = { 
      :title => "Sort by this field",
      :href => url_for(:action => action, :params => params.merge({:sort => key, :page => params[:page]}))
    }  

    link_to(text, options, html_options)
  end 

  def optionize(*args)
    result = ""
    args.each do |arg|
      result << "<option>#{arg}</option>"
    end
    return result.html_safe
  end
  
  def optionize_custom(list, selected)
    result = ""
    list.each do |arg|
      if arg == selected
        result << "<option selected=\"selected\">#{arg}</option>"
      else
        result << "<option>#{arg}</option>"
      end
    end
    return result.html_safe
  end
  
  def date_picker(elem, format, separator)
    result = "<a href=\"javascript:displayDatePicker('#{elem}', false, '#{format}', '#{separator}')\">#{image_tag('date.png', :alt => "Date", :title => "Date")}</a>"
    return result.html_safe
  end
  
  def spacer(*counts)
    spacer = "&nbsp;"
    spacers = ""
    if counts.blank?
      return spacer.html_safe
    else
      counts[0].to_i.times do |c|
        spacers << spacer
      end
      return spacers.html_safe
    end
  end

  #Converting given EST time into IST time
  def convert_to_ist_time(time)
    tz_est = Timezone.get('US/Eastern')
    utc_time = tz_est.local_to_utc(time, false)
    tz_ist = Timezone.get('Asia/Calcutta')
    ist_time = tz_ist.utc_to_local(utc_time)
    return ist_time
  end

  #Converting given IST time into EST time
  def convert_to_est_time(time)
    tz_ist = Timezone.get('Asia/Calcutta')
    utc_time = tz_ist.local_to_utc(time, false)
    tz_est = Timezone.get('US/Eastern')
    est_time = tz_est.utc_to_local(utc_time)
    return est_time
  end

  # The method 'sp_text_field' decides upon the generation of the text fields which are configured by the Facility Commission
  # This takes 5 arguments as described below:
  # 'object_name' - table name
  # 'method' - column name
  # 'show' - variable set 'true or false' based on business logic
  # 'wrapper_tag' - HTML element 'td'
  # 'options' - variable contains the attribtes of the text field
  def sp_text_field(object_name, method, show, wrapper_tag, options = {})
    ret_text = ''
    if show
      ret_text = text_field(object_name, method, options)
      ret_text = "<#{wrapper_tag}> #{ret_text} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
    end
    ret_text << "<input type = 'hidden' value ='#{show}' id='#{method}_status'/>".html_safe
    ret_text.html_safe
  end

  # The method 'sp_label' decides upon the generation of the labels which are configured by the Facility Commission
  # This takes 3 arguments as described below:
  # 'label' - label name
  # 'show' - variable set 'true or false' based on business logic
  # 'wrapper_tag' - HTML element 'th'
  def sp_label(label, show, wrapper_tag)
    ret_text = ''
    if show
      ret_text = label
      if !wrapper_tag.blank?
        ret_text = "<#{wrapper_tag}> #{ret_text} </#{wrapper_tag.split(' ').first}>"  
      else
        ret_text = "#{ret_text}"
      end      
    end
    ret_text.html_safe
  end

  # Provides the helper 'label' based on a condition to show it or not.
  # Input :
  # object_name : table name
  # method : column name
  # text : label name
  # show : variable set 'true or false' based on business logic
  # wrapper_tag : HTML wrapper elements. Eg: 'th', 'div' etc
  # Output :
  # label helper
  def hide_and_seek_label(object_name, method, text, show, wrapper_tag, options = {})
    if show
      text = label(object_name, method, text, options)
      text = "<#{wrapper_tag}> #{text} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
      text.html_safe if !text.blank?
    end
  end

  def hide_and_seek_in_place_editor_field(object, method, show, wrapper_tag,
      span_wrapper_tag, tag_options = {}, in_place_editor_options = {})
    if show
      text = span_wrapper_tag || ''
      text += in_place_editor_field(object, method, tag_options, in_place_editor_options)
      text = "<#{wrapper_tag}> #{text} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
    end
    text.html_safe if !text.blank?
  end

  # The method 'sp_checkbox' dynamically creates the checkbox and displays it based on 'show' attribute
  # arguments :
  # 'object_name' - table name
  # 'attribute_name' - column name
  # 'show' - variable set 'true or false' based on business logic
  # 'wrapper_tag' - HTML element 'td'/ 'th' etc
  # options - html options hash
  def sp_checkbox(object_name, attribute_name, show, wrapper_tag, options = {})
    object_name = nil || object_name
    if show      
      checkbox = check_box(object_name, attribute_name, options)
      checkbox = "<#{wrapper_tag}> #{checkbox} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
    end
    checkbox.html_safe if !checkbox.blank?
  end

  # The method 'sp_button' dynamically creates the button and displays it based on 'show' attribute
  # arguments :
  # 'name' - name
  # 'show' - variable set 'true or false' based on business logic
  # 'wrapper_tag' - HTML element 'td'/ 'th' etc
  # options - html options hash
  def sp_button(name, show, wrapper_tag, options = {})
    if show && name
      button = submit_tag("#{name}", options)
      button = "<#{wrapper_tag}> #{button} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
    end
    button.html_safe if !button.blank?
  end

  # This method generates the text fields with auto complete which can be shown or hidden based on a condition.
  # This takes 5 arguments as described below:
  # object_name : table name
  # method : column name
  # show : variable set 'true or false' based on business logic
  # wrapper_tag : HTML element 'td'
  # options : variable contains the attribtes of the text field
  # completion_options : completion_options of text_field_with_auto_complete
  def auto_complete_text_field(object_name, method, show, wrapper_tag, options = {}, completion_options = {})
    ret_text = nil
    if show
      ret_text = text_field_with_auto_complete(object_name, method, options, completion_options)
      ret_text = "<#{wrapper_tag}> #{ret_text} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
      ret_text.html_safe if !ret_text.blank?
    end 
  end

  # The method 'sp_select_tag' decides upon the generation of the select or drop down fields which are configured by the Facility Commission
  # This takes 6 arguments as described below:
  # 'object_name' / 'attribute_name' - either table name/column name or table name
  # 'show' - variable set 'true or false' based on business logic
  # 'wrapper_tag' - HTML element 'td'
  # 'selection_items' - variable contains the items of the drop down field
  # 'options' - variable contains the attribtes of the text field
  def sp_select_tag(object_name, attribute_name, show, wrapper_tag, selection_items, options = {})
    ret_text = ''
    name = "#{object_name}"
    if attribute_name
      name += "[#{attribute_name}]"
      name_status = attribute_name
    else
      name_status = object_name
    end
    if show
      ret_text = select_tag(name, selection_items, options)
      ret_text = "<#{wrapper_tag}> #{ret_text} </#{wrapper_tag.split(' ').first}>"  if wrapper_tag
    end
    ret_text << "<input type = 'hidden' value ='#{show}' id='#{name_status}_status'/>".html_safe
    ret_text.html_safe
  end

  #DCAPREFACTORE BEGIN 
  
  def app_root
    # RAILS3.1 TODO
    # ActionController::Base.relative_url_root()
    Rails.application.config.relative_url
    #realtive_url_root()
  end
  
  #DCAPREFACTORE Stop
  #used to calculate the tooth number for claim level eobs
  def claim_level_tooth_number(service_line, claim_level_eob)
    tooth_number = ""
    tooth_number_array = []
    if claim_level_eob
      service_line.each do |svc|
        unless svc.blank?
          if svc.class.to_s == 'ClaimServiceInformation'
            tooth_code = svc.tooth_code
            unless tooth_code.blank?          
              space_removed = tooth_code.gsub(/\s+/, "")
              space_removed.split(',').each do |tc|
                tooth_number_array = tooth_number_array.push(tc.split(':').first)
              end
            end
            logger.debug "tooth_number : #{tooth_number}"
          end
        end
      end     
      tooth_number = tooth_number_array.delete_if {|c| c.empty? }.uniq.join(',') unless tooth_number_array.blank?
    end
    return tooth_number
  end

  #used to calculate the total charge for claim level eobs
  def claim_level_charge( service_line )
    charge_amount = service_line.map{ |f| f.service_procedure_charge_amount.to_f}.sum
    sprintf("%.2f", charge_amount)
  end
  
  def claim_level_earliest_dt( service_line )
    claim_from_date = service_line.map{ |svc| svc.date_of_service_from }.select {|d| !d.blank?}.flatten.sort.first
    if claim_from_date 
      claim_from_date.strftime("%m/%d/%y")
    else
      "mm/dd/yy"
    end
  end
  
  def claim_level_latest_date( service_line )
    claim_to_date = service_line.map{ |svc| svc.date_of_service_to }.select {|d| !d.blank?}.flatten.sort.last
    if claim_to_date 
      claim_to_date.strftime("%m/%d/%y")
    else
      "mm/dd/yy"
    end
  end
  
  def claim_level_eob_status(insurance_payment_eob) 
    if insurance_payment_eob.category == "claim"
      claim_level_eob = true
    end
    claim_level_eob
  end
 
  def claim_level_validation(claim_level_eob)
    "validate-reasoncode validate-alphanumeric"    unless claim_level_eob.blank?
  end
  def claim_level_validation_desc(claim_level_eob)
    "validate-reasoncode"    unless claim_level_eob.blank?
  end
  def required_validation(claim_level_eob)   
    "required" unless (claim_level_eob.blank?)
  end 

  def btch_criteria_v2
    conditions = []
    values = []
    and_or_or = " AND "
    if (params[:first_criteria] == params[:second_criteria])
      and_or_or = " OR "
    end
    [[params[:first_criteria], params[:first_to_find]],
      [params[:second_criteria], params[:second_to_find]]].each do |criteria|
      unless criteria.last.strip.blank?
        case criteria.first
        when 'Date'
          begin
            date = Date.strptime(criteria.last,"%m/%d/%y").to_s
            conditions << " date = ?"
            values << date
          rescue ArgumentError
            flash[:notice] = "Invalid date format, use mm/dd/yy"
            conditions = []
            return "",[]
          end
        when 'Facility'
          conditions << " facilities.name like ? "
          values << "%#{criteria.last.strip}%"
        when 'Batch ID'
          conditions << " batchid like ?"
          values << "%#{criteria.last.strip}%"
        when  'Status'
          conditions << " batches.status like ?"
          values << "%#{criteria.last.strip}%"
        end
      end
    end
    conditions = "jobs.is_excluded = 0 and (".concat(conditions.join(and_or_or)).concat(")")
    return conditions, *values
  end
 
  # Common helper method for all Batch base filters
  def frame_batch_criteria(initial_condition = "") 
    conditions = ''
    result = []
    case params[:criteria]
    when 'Batch ID'
      batchid = "%#{params[:to_find].strip}%"
      batchid =  batchid.gsub!("_","\\_") if batchid.include?'_'
      conditions << " batchid like ?"
      result.push(batchid)
    when 'Date','Batch Date'
      begin
        date = Date.strptime(params[:to_find],"%m/%d/%y").to_s
        conditions << " date #{params[:compare]} ?"
        result.push(date)
      rescue ArgumentError
        flash[:notice] = "Invalid date format, use mm/dd/yy"
        return ""
      end
    when 'Facility', 'Site Name', 'Facility Name'
      flash[:notice] = "String search, all operators are ignored."
      conditions << " facilities.name like ? "
      result.push('%'+params[:to_find].strip+'%')
    when 'Client'
      flash[:notice] = "String search, all operators are ignored."
      conditions << " clients.name like ? "
      result.push('%'+params[:to_find].strip+'%')
    when 'Status'
      flash[:notice] = "String search, all operators are ignored."
      to_find_status = params[:to_find].strip.upcase
      if to_find_status == "IN PROCESS"
        conditions << " batches.status = '#{BatchStatus::PROCESSING}' and (batches.comment IS NULL or LENGTH(batches.comment) = 0)"
      elsif to_find_status == "COMPLETED"
        conditions << " batches.status IN ('#{BatchStatus::COMPLETED}','#{BatchStatus::OUTPUT_READY}') and (batches.comment IS NULL or LENGTH(batches.comment) = 0)"
      elsif to_find_status == "NEW"
        conditions << " batches.status = '#{BatchStatus::NEW}' and (batches.comment IS NULL or LENGTH(batches.comment) = 0)"
      elsif to_find_status == "PENDING"
        conditions << " batches.comment IS NOT NULL and LENGTH(batches.comment) > 0"
      else
        conditions << " status like ? "
        result.push(params[:to_find].strip)
      end
    when 'Site Number', 'Client Code'
      conditions << " facilities.sitecode #{params[:compare]} ?"
      result.push(params[:to_find])
    when 'Arrival Time'
      begin
        arrival_date = Date.strptime(params[:to_find],"%m/%d/%y").to_s
        conditions << " left(batches.arrival_time,10) #{params[:compare]} ?"
        result.push(arrival_date)
      rescue ArgumentError
        flash[:notice] = "Invalid date format"
        return conditions
      end
    when 'Turn Around Time'
      begin
        turn_around_time = Date.strptime(params[:to_find],"%m/%d/%y").to_s
        conditions << " left(batches.target_time,10) #{params[:compare]} ?"
        result.push(turn_around_time)
      rescue ArgumentError
        flash[:notice] = "Invalid Date/Time format"
        return conditions
      end
    when 'Estimated Completion Time'
      begin
        # The input value will be mm/dd/yy HH:MM. So the input value has to splitted in to two values - date and time
        array_estimated_completion_datetime = []
        array_estimated_completion_datetime = params[:to_find].to_s.strip.split
        estimated_completion_date = Date.strptime(array_estimated_completion_datetime[0].to_s,"%m/%d/%y")
        # Concating the date and time together to get the datetime value for the SQL query input
        estimated_completion_date_time = estimated_completion_date.to_s + " " + array_estimated_completion_datetime[1].to_s + ":00"
        conditions << " batches.estimated_completion_time #{params[:compare]} ?"
        result.push(estimated_completion_date_time)
      rescue Exception => e
        flash[:notice] = "Invalid date/time format"
      end
    when 'Batch Type'
      batch_type = params[:to_find].to_s.upcase
      if batch_type == "PAYMENT"
        conditions << " batches.correspondence = 'false'"
      elsif batch_type == "CORRESPONDENCE"
        conditions << " batches.correspondence = 'true'"
      else
        flash[:notice] = "Invalid Search Criteria."
      end
    when 'Estimated EOB'
      conditions << "batch.estimated_eobs #{params[:compare]} ?"
      result.push(params[:to_find])
    when 'Allocation Type'
      flash[:notice] = "String search, all operators are ignored."
      parameter = params[:to_find].to_s.upcase.strip
      if parameter == 'MANUAL'
        condition = 'batches.facility_wise_auto_allocation_enabled = 0 and batches.payer_wise_auto_allocation_enabled = 0'
      elsif parameter == 'FACILITY WISE' || parameter == 'FACILITY'
        condition = 'batches.facility_wise_auto_allocation_enabled = 1'
      elsif parameter == 'PAYER WISE' || parameter == 'PAYER'
        condition = 'batches.payer_wise_auto_allocation_enabled = 1'
      else
        condition = 'batches.facility_wise_auto_allocation_enabled IS NULL and batches.payer_wise_auto_allocation_enabled IS NULL'
      end
      conditions << condition.to_s
    when 'RMS Provider ID'
      conditions << " meta_batch_informations.provider_code #{params[:compare]} ?"
      result.push(params[:to_find])
    end
    if !initial_condition.blank?
      if !conditions.blank?
        conditions << " and "
      end
      conditions << initial_condition
    end
    return conditions, result
  end

  def frame_order_criteria
    case params[:criteria]
    when 'Arrival Time'
      "batches.arrival_time DESC"
    when 'Date', 'Batch Date'
      "batches.date DESC"
    when 'Turn Around Time'
      "batches.target_time DESC"
    when 'Estimated Completion Time'
      "batches.estimated_completion_time DESC"
    else
      "batches.date DESC"
    end
  end
  def frame_payer_criteria(conditions)
    search_field = params[:to_find].strip
    compare = params[:compare]
    criteria = params[:criteria]
    case criteria
    when 'Payer Id'
      conditions << "&& payers.payid like '%#{search_field}%'"
    when 'Payer'
      conditions << "&& payers.payer like '%#{search_field}%'"
    when 'ERA Payer Name'
      conditions << "&& payers.era_payer_name like '%#{search_field}%'"
    when 'Payer Type'
      if ("INSURANCE".include?(search_field.upcase))
        conditions << "&& payers.payer_type REGEXP '^[0-9]+$'"
      else
        conditions << "&& payers.payer_type like '%#{search_field}%'"
      end
    when 'Address-1'
      conditions << "&& payers.pay_address_one like '%#{search_field}%'"
    when 'Address-2'
      conditions << "&& payers.pay_address_two like '%#{search_field}%'"
    when 'Payer City'
      conditions << "&& payers.payer_city like '%#{search_field}%'"
    when 'Payer State'
      conditions << "&& payers.payer_state like '%#{search_field}%'"
    when 'Payer Zip'
      conditions << "&& payers.payer_zip like '%#{search_field}%'"
    when 'Payer Website'
      conditions << "&& payers.website like '%#{search_field}%'"
    when 'Payer Status'
      conditions << "&& payers.status like '%#{search_field}%'"
    when 'Footnote Indicator'
      if ("YES".include?(search_field.upcase))
        conditions << "&& payers.footnote_indicator = '1' "
      elsif ("NO".include?(search_field.upcase))
        conditions << "&& payers.footnote_indicator = '0' "
      end
    when 'RC Set Name'
      search_field =  search_field.gsub!("_","\\_") if search_field.include?'_'
      conditions << "&& reason_code_set_names.name like '%#{search_field}%'"
    when 'EOBs Per Image'
      if(compare == '=')
        conditions << "&& payers.eobs_per_image = '#{search_field}'"
      elsif(compare == '<')
        conditions << "&& payers.eobs_per_image < '#{search_field}'"
      elsif(compare == '>')
        conditions << "&& payers.eobs_per_image > '#{search_field}'"
      end
    when 'ABA Routing #'
      conditions << "&& micr_line_informations.aba_routing_number like '%#{search_field}%'"
    when 'Payer Account #'
      conditions << "&& micr_line_informations.payer_account_number like '%#{search_field}%'"
    when 'MICR Status'
      conditions << "&& micr_line_informations.status like '%#{search_field}%'"
    when 'Temp PayId'
      conditions << "&& micr_line_informations.payid_temp like '%#{search_field}%'"
    when 'TAT of the Batch'
      if(compare == '=')
        conditions << "&& payers.batch_target_time = '#{search_field}'"
      elsif(compare == '<')
        conditions << "&& payers.batch_target_time < '#{search_field}'"
      elsif(compare == '>')
        conditions << "&& payers.batch_target_time > '#{search_field}'"
      end
    end
    conditions

  end

  def get_date_condition(date, flash_notice, conditions, values, compare_val)

    if date.present?
      date_formated, flash_notice = normalize_date_format(date)
      if date_formated.present?
        conditions << " DATE(batches.date) #{compare_val} ?"
        values << date_formated
      end
    end
    return conditions, values
  end

  def frame_eob_report_criteria
    conditions = []
    values = []
    flash_notice = ''
    client = params[:client] unless params[:client].blank?
    facility = params[:plan_type_facility] unless params[:plan_type_facility].blank?
    to_date = params[:to_date].strip unless params[:to_date].blank?
    from_date = params[:from_date].strip unless params[:from_date].blank?
    batchid = params[:batch_id].strip unless params[:batch_id].blank?
    check_number = params[:check_number].strip unless params[:check_number].blank?
    report_layout = params[:eob_report_layout] unless params[:eob_report_layout].blank?
    conditions << " batches.status != '#{BatchStatus::NEW}'"

    if from_date.present?
      compare_val = ">="
      conditions, values = get_date_condition(from_date, flash_notice, conditions, values, compare_val)
    end
    
    if to_date.present?
      compare_val = "<="
      conditions, values = get_date_condition(to_date, flash_notice, conditions, values, compare_val)
    end
    
    if batchid.present?
      conditions << " batches.batchid like ?"
      values << "%#{batchid}%"
    end

    if facility.present?
      conditions << " batches.facility_id = ? "
      values << facility
    end
    if client.present?
      conditions << " batches.client_id = ? "
      values << client
    end
    conditions = conditions.join(" AND ")
    
    return conditions, *values
  end

  def start_generating_eob_report(batches)
    start_time = Time.now
    check_number = params[:check_number].strip unless params[:check_number].blank?
    eob_report_layout = params[:eob_report_layout].downcase.gsub(' ', '_') unless params[:eob_report_layout].blank?
    file_name = "#{params[:from_date]}_eob_report"
    extension = ".xls"
    file_name = file_name + extension
    eob_report = AggregateReport.new(current_user)
    checks = batches.collect(&:checks_for_eob_report).flatten
    if check_number.present?
      checks = checks.delete_if {|check| check.check_number != "#{check_number}"}
    end
    csv_string = eob_report.send :generate_aggregate_835_report, checks, eob_report_layout
    update_log_data(batches, file_name, start_time)
    send_data csv_string, :type => "text/csv",
      :filename => file_name,
      :disposition => 'attachment'
  end

  def update_log_data(batches, file_name, start_time)
    end_time = Time.now
    batches.each do |batch|
      OutputActivityLog.record_activity([batch.id], 'EOB Report Generated',
        'EOB_Report', file_name, nil, start_time, end_time, current_user.id)
    end
  end
  
  def foot_note_types
    [['Non-Footnote', false], ['Footnote', true]]
  end

  def payer_types
    [['Insurance', 'Insurance'], ['Patpay', 'PatPay']]
  end
  
  def time_diff_from_now tim_utc
    if !tim_utc.blank?
      diff = Date.parse(tim_utc.to_s + " UTC").to_time  - Time.now
      diff_str =""
      if (diff < 0)
        diff = diff * -1
        diff_str = "-"
      end
      h = (diff/1.hour)
      m = (diff%1.hour)/1.minute
      s = (diff%1.minute)
      diff_str = diff_str + "#{h.to_i}:#{m.to_i}:#{s.to_i}"
    end
  end

  def format_payer_type payer_type
    payer_type = "Insurance" if payer_type =~ /^\d+$/
    payer_type
  end

  def get_valid_hipaa_codes_and_unique_codes_in_job(reason_codes)
    valid_hipaa_codes_and_unique_codes = ""
    unique_codes_string = get_unique_codes(reason_codes)
    hipaa_code_array = $HIPAA_CODES
    hipaa_codes_array = []
    hipaa_code_array.each do |id_and_code_and_description|
      hipaa_codes_array << id_and_code_and_description[1]
    end    
    hipaa_codes_string = hipaa_codes_array.join(";") if hipaa_codes_array.present?
    valid_hipaa_codes_and_unique_codes = unique_codes_string if unique_codes_string.present?
    valid_hipaa_codes_and_unique_codes += ";" + hipaa_codes_string if hipaa_codes_string.present?
    valid_hipaa_codes_and_unique_codes
  end

  # +----------------------------------------------------------------------------+
  # This method is for getting Unique Codes associated to a job. This is used in |
  # reason_code_information_controller/list and insurance_payment_eob_controller/|
  # show_eob_grid.                                                               |
  # Input  : reason_codes collection                                             |
  # Output : A string of unique_codes , separated by semicolon(;).               |
  # Implementation:                                                              |
  # Step1: Iterate over reason_codes collection                                  |
  # Step2: Get all unique_codes associated each reason_code                      |
  # Step3: Get a string of unique_codes, separated by ';'.                       |
  # +----------------------------------------------------------------------------+
  def get_unique_codes(reason_codes)
    unique_codes = []
    reason_codes.each do |rc|
      unique_codes << rc.get_unique_code
    end
    unique_codes = unique_codes.blank? ? "" : unique_codes.join(";")
  end
  
  def get_mpi_index_name
    config = Rails.configuration
    return config.database_configuration["mpi_data_#{Rails.env}"]["database"] << "_core"
  end

  # This method provides the UI validation for the Patient Account Number in the Nextgen grid.
  # This is used by both insurance_payment_eobs/claimqa and datacaptures/_patient_pay
  def account_number_validation_for_nextgen(facility)
    validation = ""
    if facility.details[:patient_account_number_hyphen_format]
      if $IS_PARTNER_BAC
        validation << " validate-patient_account_number"
      else
        validation << " validate-alphanumeric-hyphen-period-forwardslash"
        validation << " validate-conecutive-special-characters-for-patient-account-number-nonbank"
        validation << " validate-limit-of-special-characters"
      end
    else
      validation << " validate-alphanumeric"
    end
    if not Client.is_client_orbograph?(@client_name)
      if @processor_view
        validation << " validate-length-12-for-nextgen-account-number"
      else
        validation << " validate-length-16-for-nextgen-account-number"
      end
    end
    validation
  end

  def display(value)
    value.blank? ? '-' : value
  end
  def approved_payer_search_list
    ['Payer Id','Payer', 'ERA Payer Name', 'Payer Type','Address-1','Address-2','ABA Routing #','Payer Account #','Payer City','Payer State','Payer Zip','Payer Website','Payer Status','Footnote Indicator','RC Set Name','EOBs Per Image']
  end
  def non_approved_payer_search_list
    ['Payer Id','Payer', 'ERA Payer Name', 'Payer Type','Address-1','Address-2','ABA Routing #','Payer Account #','Payer City','Payer State','Payer Zip','Payer Status','Micr Status','Footnote Indicator','Temp PayId','TAT of the Batch ']
  end
  def link_to_for_patient_pay_simplified
    link_to "PATIENT PAY [y]", {:controller => 'insurance_payment_eobs',:action => 'show_eob_grid', :tab => "patient_pay"},
      {:target => "myiframe", :style => "background:#195b6b;color: #FFFFFF; padding:2px; margin-right:3px;", :class => "title_link", :accesskey => "y",:onclick=>"uncheckClaimLevelEob();enableComplete_patientpay()",:completed_eob_value => 'false'} 
  end

  def grid_type    
    hidden_field 'grid', 'type', :value => @grid_type
  end

  def upcase_hash_value(hash)
    hash.each { |k, v| hash[k] = v.upcase unless v.blank?}
  end

  # Compatible to Safari browser
  def compatible_csv
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=' + params[:action] + '.csv'          
  end

  def find_attribute_from_text_column(text_column, to_search)
    found = false
    key_value_array = text_column.to_s.split("\n")
    key_value_array.each do |item|
      if item.strip == to_search
        found = true
        break
      end
    end
    found
  end

  def us_states
    {
      'AL' => 'Alabama',
      'AK' => 'Alaska',
      'AZ' => 'Arizona',
      'AR' => 'Arkansas',
      'CA' => 'California',
      'CO' => 'Colorado',
      'CT' => 'Connecticut',
      'DE' => 'Delaware',
      'FL' => 'Florida',
      'GA' => 'Georgia',
      'HI' => 'Hawaii',
      'ID' => 'Idaho',
      'IL' => 'Illinois',
      'IN' => 'Indiana',
      'IA' => 'Iowa',
      'KS' => 'Kansas',
      'KY' => 'Kentucky',
      'LA' => 'Louisiana',
      'ME' => 'Maine',
      'MD' => 'Maryland',
      'MA' => 'Massachusetts',
      'MI' => 'Michigan',
      'MN' => 'Minnesota',
      'MS' => 'Mississippi',
      'MO' => 'Missouri',
      'MT' => 'Montana',
      'NE' => 'Nebraska',
      'NV' => 'Nevada',
      'NH' => 'New Hampshire',
      'NJ' => 'New Jersey',
      'NM' => 'New Mexico',
      'NY' => 'New York',
      'NC' => 'North Carolina',
      'ND' => 'North Dakota',
      'OH' => 'Ohio',
      'OK' => 'Oklahoma',
      'OR' => 'Oregon',
      'PA' => 'Pennsylvania',
      'RI' => 'Rhode Island',
      'SC' => 'South Carolina',
      'SD' => 'South Dakota',
      'TN' => 'Tennessee',
      'TX' => 'Texas',
      'UT' => 'Utah',
      'VT' => 'Vermont',
      'VI' => 'Virgin Island',
      'VA' => 'Virginia',
      'WA' => 'Washington',
      'WV' => 'West Virginia',
      'WI' => 'Wisconsin',
      'WY' => 'Wyoming'
    }

  end

  def job_type(job, parent_jobs)
    type = ''
    split_from_created_job = job.parent_job_id? ? parent_jobs.select{|p| p.id == job.parent_job_id}.first.try(:split_parent_job_id) : nil if parent_jobs
    if !job.split_parent_job_id.blank? || split_from_created_job
      type = 'D'
    else 
      type = 'O' 
    end
    type
  end
  
  # Remove the private access when using
  private
  def stream_csv(title, extension)
    filename = title + extension

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render :text => Proc.new { |response, output|
      if(extension == ".csv" or extension == ".txt")
        csv = CSV.new(output, :row_sep => "\r\n")
      elsif extension == ".xls"
        csv = CSV.new(output, :row_sep => "\r\n", :col_sep => "\t")
      end
      yield csv
    }

  end

  
end
