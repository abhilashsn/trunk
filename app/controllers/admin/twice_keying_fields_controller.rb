class Admin::TwiceKeyingFieldsController < ApplicationController
  require_role ["admin","supervisor"], :except => :get_field_names
  layout 'standard'
  require 'will_paginate/array'  
 
  def list
    ActiveRecord::Base.connection().execute("SET SESSION group_concat_max_len = 10485760")
    @twice_keying_field_records = TwiceKeyingField.find_by_sql(" SELECT
      twice_keying_fields.id AS id, twice_keying_fields.field_name, \
      twice_keying_fields.created_at, twice_keying_fields.group_no, \
      twice_keying_fields.start_date, twice_keying_fields.end_date, \
      clients.id AS client_id, clients.name AS client_name, \
      group_concat(distinct facilities.name) AS facility_name, \
      payers.payer AS payer_name, payers.payid AS payid, \
      payers.id AS payer_id, group_concat(distinct users.name) AS processor_name, \
      group_concat(distinct users.login) AS processor_login FROM `twice_keying_fields` \
      INNER JOIN clients ON clients.id = twice_keying_fields.client_id
      LEFT OUTER JOIN facilities ON facilities.id = twice_keying_fields.facility_id
      LEFT OUTER JOIN payers ON payers.reason_code_set_name_id = twice_keying_fields.reason_code_set_name_id
      LEFT OUTER JOIN users ON users.id = twice_keying_fields.processor_id  \
      GROUP BY twice_keying_fields.field_name, twice_keying_fields.group_no ORDER BY  twice_keying_fields.end_date desc ").paginate(:page => params[:page], :per_page => 15)
    date = Date.today
    today_in_utc = Time.utc(date.year, date.month, date.day)
    today_in_array = today_in_utc.to_s.split(' ')
    today_in_string = today_in_array[0]
    @today = Date.parse(today_in_string.to_s)
  end

  def edit
    @mode = params[:mode]
    if !params[:id].blank?
      @twice_keying_record = TwiceKeyingField.select("
        twice_keying_fields.id AS id, twice_keying_fields.field_name as field_name, \
        twice_keying_fields.start_date, twice_keying_fields.end_date, \
        twice_keying_fields.client_id, group_concat(distinct twice_keying_fields.facility_id) as facility_ids, twice_keying_fields.group_no,\
        group_concat(distinct twice_keying_fields.processor_id) as processor_ids, group_concat(distinct users.login) AS processor_login, \
        clients.name AS client_name, group_concat(distinct facilities.name) AS facility_name, \
        payers.payer AS payer_name, payers.payid AS payid, payers.id AS payer_id").
        joins("INNER JOIN clients ON clients.id = twice_keying_fields.client_id
        LEFT OUTER JOIN facilities ON facilities.id = twice_keying_fields.facility_id
        LEFT OUTER JOIN payers ON payers.reason_code_set_name_id = twice_keying_fields.reason_code_set_name_id
        LEFT OUTER JOIN users ON users.id = twice_keying_fields.processor_id").group("twice_keying_fields.group_no").where(:group_no => params[:group_no].to_i, :field_name => params[:field_name]).first
      
      @payer = Payer.find(params[:payer]) unless params[:payer].blank?
      @clients = Client.find(:all).sort.collect {|c| [c.name.upcase, c.id]}
      @facilities = []
      @selected_facility_id = []
      if @twice_keying_record
        facilities = Facility.where(:client_id => @twice_keying_record.client_id).order("name ASC")
        if !@twice_keying_record.facility_ids.blank?
          selected_facility = nil
          facilities.each do |facility|
            if (@twice_keying_record.facility_ids.split(',').include?("#{facility.id}"))
              selected_facility = facility
              @selected_facility_id << facility.id
            else
              @facilities << facility
            end
            @facilities.insert(0, selected_facility) if selected_facility
          end
        else
          @facilities = facilities
        end
      end
    else
      flash[:notice] = 'Please select a record'
    end
    @facilities = @facilities.uniq unless @facilities.blank?
  end

  def create
    invalid_message = validate_attributes
    last_twice_keying_record = TwiceKeyingField.last
    if invalid_message
      flash[:notice] = invalid_message
    else
      params[:group_no] = TwiceKeyingField.get_group_no last_twice_keying_record
      twice_keying_records = TwiceKeyingField.formulate_array_of_attributes(params)
      TwiceKeyingField.create_or_update(twice_keying_records)
      flash[:notice] = "Double Keying Record is saved"
    end
    redirect_to :controller => "admin/pop_up", :action => 'add_message',
      :mode => params[:mode]
  end

  def update
    invalid_message = validate_attributes
    if invalid_message
      flash[:notice] = invalid_message
      redirect_to :controller => "admin/twice_keying_fields", :action => 'edit'
    else
      twice_keying_records = TwiceKeyingField.formulate_array_of_attributes(params)
      TwiceKeyingField.create_or_update(twice_keying_records, params[:previous_field_name])
      flash[:notice] = "Double Keying Record is saved"
      redirect_to :action => 'list'
    end
  end

  def validate_attributes
    if params[:client_id].blank?
      message = "Please select a client"
      return message
    end
    if params[:field_names].blank?
      message = "Please select a field name"
      return message
    end
    if params.has_key?(:duration_number) && params[:duration_number].blank?
      message = "Please select duration"
      return message
    end
    if params.has_key?(:duration_type) && params[:duration_type].blank?
      message = "Please select duration"
      return message
    end
    if params.has_key?(:start_date) && params[:start_date].blank?
      message = "Please select start date"
      return message
    end
    if params.has_key?(:end_date) && params[:end_date].blank?
      message = "Please select end date"
      return message
    end
  end

  def delete
    hash_of_ids_to_delete = params[:to_delete]
    if !hash_of_ids_to_delete.blank?
      hash_of_ids_to_delete.delete_if do |key, value|
        value == "0"
      end
      ids_to_delete = hash_of_ids_to_delete.keys
      hash = build_group_no_hash ids_to_delete
      group_nos = hash.keys
      unless group_nos.blank?
        delete_records group_nos, hash
        flash[:notice] = "  Record(s) Deleted."
      end
    end
    redirect_to :action => 'list', :page => params[:page]
  end

  def build_group_no_hash ids_to_delete
    hash = {}
    ids_to_delete.each_index do |index|
      if hash.has_key?(ids_to_delete[index][0])
        hash[ids_to_delete[index][0]] <<  ids_to_delete[index].split(',')[1]
      else
        hash[ids_to_delete[index][0]] = ids_to_delete[index].split(',')[1]
      end
    end
    hash
  end

  def delete_records group_nos, hash
    group_nos.each do |group_no|
      conditions = TwiceKeyingField.frame_delete_conditions hash, group_no
      TwiceKeyingField.where(conditions).destroy_all
    end
  end

  def get_field_names
    field_names = ''
    client_id = params[:client_id]
    facility_id = params[:facility_id]
    rc_set_name_id = params[:reason_code_set_name_id]
    if !client_id.blank? && !facility_id.blank? && !rc_set_name_id.blank?
      field_names = TwiceKeyingField.get_all_twice_keying_fields(client_id, facility_id, current_user.id, rc_set_name_id)
    end
    render :text => field_names.to_json
  end

end

