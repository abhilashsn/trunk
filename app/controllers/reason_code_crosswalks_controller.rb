class ReasonCodeCrosswalksController < ApplicationController
  layout "standard"
  require_role ["admin", "supervisor", "manager"]
  before_filter :prepare
  
  def index
    redirect_to :action => :list    
  end


  def new
    if validate_before_create
      @rccfsn  = ReasonCodesClientsFacilitiesSetName.new({:reason_code_id => @reason_code.id})
      @cross_walk_codes = {}
      @clients = Client.select([:name,:id]).all
      @facilities = Facility.select([:name,:id]).all
    else

    end    
  end
  
  def edit
    @rccfsn  =  ReasonCodesClientsFacilitiesSetName.find(params[:id])
    @reason_code = @rccfsn.reason_code
    set_name = @reason_code.reason_code_set_name
    @payer = Payer.find_by_reason_code_set_name_id(set_name.id)
    @clients = Client.select([:name,:id]).all 
    @facilities = Facility.select([:name,:id]).all
    @cross_walk_codes = {}	
    #@cross_walk_codes = ReasonCodeCrosswalk.new(@payer,nil,@rccfsn.client,@rccfsn.facility).get_crosswalked_codes_for_reason_code(@reason_code)
    @cross_walk_codes = @rccfsn.get_codes_crosswalked if @rccfsn
  end

  def create
    if !$IS_PARTNER_BAC && validate_before_create
      @rccfsn  = ReasonCodesClientsFacilitiesSetName.new({:reason_code_id => @reason_code.id})
      set_attributes params
      if @rccfsn.save
        @rccfsn.associate_hippa_and_client_codes(params)
        remark_codes_to_associate = params[:optional_ansi_remark_codes].to_s.split(",")
        remark_code_crosswalk_ids = params[:remark_code_crosswalk_ids].to_s.split(",")
        associate_client_and_facility_ids = {
          :facility_id => params[:facility_id],
          :client_id => params[:client_id]
        }
        remark_code_crosswalked_and_client_and_facility_ids = {
          :rc_remark_code_ids => remark_code_crosswalk_ids,
          :facility_id => params[:remark_code_crosswalked_facility_id],
          :client_id => params[:remark_code_crosswalked_client_id]
        }
        @reason_code.associate_remark_codes(remark_codes_to_associate, associate_client_and_facility_ids,
          remark_code_crosswalked_and_client_and_facility_ids)

        flash[:notice] = "Successfully updated."
        redirect_to :controller => "reason_code_crosswalks", :action=>"list", :payer_id=>@payer.id, :reason_code_id=>@reason_code.id
      else
        #flash[:notice] = "Error while creating cross walks."
        #redirect_to :controller => "reason_code_crosswalks", :action=>"new", :payer_id=>@payer.id, :reason_code_id=>@reason_code.id
        @clients = Client.select([:name,:id]).all
        @facilities = Facility.select([:name,:id]).all 
        @cross_walk_codes = {}
        render :action => 'new'
      end
    else
      flash[:notice] = "Cannot find records."
      redirect_to :controller => "reason_code_crosswalks", :action=>"list"
    end
  end

  def update
    @rccfsn  =  ReasonCodesClientsFacilitiesSetName.find(params[:id])
    @reason_code = @rccfsn.reason_code
    set_name = @reason_code.reason_code_set_name
    @payer = Payer.find_by_reason_code_set_name_id(set_name.id)
    set_attributes params
    if $IS_PARTNER_BAC 
      flash[:notice] = "Cannot create cross walks"
      redirect_to :controller => "reason_code_crosswalks", :action=>"list", :payer_id=>@payer.id, :reason_code_id=>@reason_code.id      
    elsif  @rccfsn.save
      @rccfsn.associate_hippa_and_client_codes(params)
      remark_codes_to_associate = params[:optional_ansi_remark_codes].to_s.split(",")
      remark_code_crosswalk_ids = params[:remark_code_crosswalk_ids].to_s.split(",")
      associate_client_and_facility_ids = {
        :facility_id => params[:facility_id],
        :client_id => params[:client_id]
      }
      remark_code_crosswalked_and_client_and_facility_ids = {
        :rc_remark_code_ids => remark_code_crosswalk_ids,
        :facility_id => params[:remark_code_crosswalked_facility_id],
        :client_id => params[:remark_code_crosswalked_client_id]
      }
      @reason_code.associate_remark_codes(remark_codes_to_associate, associate_client_and_facility_ids,
        remark_code_crosswalked_and_client_and_facility_ids)
      flash[:notice] = "Successfully updated."
      redirect_to :controller => "reason_code_crosswalks", :action=>"list", :payer_id=>@payer.id, :reason_code_id=>@reason_code.id      
    else
      @clients = Client.select([:name,:id]).all 
      @facilities = Facility.select([:name,:id]).all
      @cross_walk_codes = {}	
      @cross_walk_codes = @rccfsn.get_codes_crosswalked if @rccfsn
      render :action => 'edit'
    end
  end

  def destroy    
    rccfsn = ReasonCodesClientsFacilitiesSetName.find(params[:id])
    if !$IS_PARTNER_BAC && rccfsn
      rccfsn.reason_code.delete_remark_code_crosswalk(rccfsn.client_id, rccfsn.facility_id)      
      if rccfsn.destroy
        flash[:notice] = "Successfully deleted records."
      else
        flash[:notice] = "Error while deleting records."
      end
    else
      flash[:notice] = "Error while deleting records."
    end
    #redirect_to :controller => "reason_code_crosswalks", :action=>"list", :payer_id=>payer.id, :reason_code_id=>reason_code.id      
    redirect_to  request.env["HTTP_REFERER"]
  end  
  
  def list
    @filter_available = true
    if params[:reason_code_id].present?
      @reason_code = ReasonCode.find(params[:reason_code_id])      
      if !params[:payer_id].blank?
        @payer = Payer.find(params[:payer_id])
      else
        @payer = Payer.find_by_reason_code_set_name_id(@reason_code.reason_code_set_name_id)
      end
      
      conditions = "reason_codes_clients_facilities_set_names.reason_code_id = #{@reason_code.id}"
      @filter_available = false
    elsif !params[:set_name_generic_search_field].to_s.strip.blank? || !params[:code_generic_search_field].to_s.strip.blank? || !params[:description_generic_search_field].to_s.strip.blank? 
      conditions = condition_for_fetching_all_levels_of_crosswalk_records
    else
      conditions = condition_for_fetching_a_crosswalk_record
    end 
    if !conditions.blank?
      conditions = conditions + " AND reason_codes_clients_facilities_set_names.active_indicator = '1'  AND reason_codes.active = '1' "
      @reason_codes_crosswalk_items = ReasonCodesClientsFacilitiesSetName.paginate(
        :conditions => conditions, :page => params[:page], :per_page => 10).
        joins("INNER JOIN reason_codes ON reason_codes.id = reason_codes_clients_facilities_set_names.reason_code_id \
        INNER JOIN reason_code_set_names ON reason_code_set_names.id = reason_codes.reason_code_set_name_id \
        LEFT OUTER JOIN clients ON clients.id = reason_codes_clients_facilities_set_names.client_id \
        LEFT OUTER JOIN facilities ON facilities.id = reason_codes_clients_facilities_set_names.facility_id \        
        LEFT OUTER JOIN hipaa_codes  ON hipaa_codes.id = reason_codes_clients_facilities_set_names.hipaa_code_id").
        order("reason_codes.reason_code_set_name_id, \
        reason_codes_clients_facilities_set_names.reason_code_id  , \
        reason_codes_clients_facilities_set_names.client_id, \
        reason_codes_clients_facilities_set_names.facility_id").
        select("reason_codes_clients_facilities_set_names.id, \
        reason_codes_clients_facilities_set_names.id as crosswalk_record_id, \
        reason_codes.reason_code as code, \
        reason_codes.reason_code_description as description, \
        reason_code_set_names.name as set_name, \
        facilities.sitecode as site_code, \
        reason_codes_clients_facilities_set_names.client_id as client_id, \
        reason_codes.active as active,\
        reason_codes_clients_facilities_set_names.facility_id as facility_id, \
        hipaa_codes.hipaa_adjustment_code as hcode, \
        clients.group_code as group_code")
    end
  end
  
  def show
    begin
      crosswalk_object = ReasonCodesClientsFacilitiesSetName.find(:first, :conditions => ["id = ?", params[:id]],
        :include => [:facility, :client, {:reason_code => :reason_code_set_name}])
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Record not found"
      redirect_to :action => :list
    end
    client = crosswalk_object.client
    facility = crosswalk_object.facility
    @reason_code_object = crosswalk_object.reason_code
    set_name = @reason_code_object.reason_code_set_name
    @set_name = set_name.name
         
    if !set_name.blank? && !@reason_code_object.blank?
      crosswalk_item  = ReasonCodeCrosswalk.new(nil, nil, client, facility, set_name)
      if client.blank? && facility.blank?
        @crosswalk_level = 'GLOBAL LEVEL'
        @entity_name = @set_name
        @entity_code = ''        
        @crosswalk_item = crosswalk_item.get_crosswalked_codes_for_a_reason_code_at_global_level(@reason_code_object) 
      elsif !client.blank? && facility.blank?
        @crosswalk_level = 'CLIENT LEVEL'
        @entity_name = client.name
        @entity_code = client.group_code          
        @crosswalk_item = crosswalk_item.get_crosswalked_codes_for_a_reason_code_at_client_level(@reason_code_object)
      elsif client.blank? && !facility.blank?
        @crosswalk_level = 'FACILITY LEVEL'
        @entity_name = facility.name
        @entity_code = facility.sitecode         
        @crosswalk_item = crosswalk_item.get_crosswalked_codes_for_a_reason_code_at_site_level(@reason_code_object)
      else
        @crosswalk_item = {}
      end        
    end
  end
  
  private

  def condition_for_fetching_all_levels_of_crosswalk_records
    set_name_search_field = params[:set_name_generic_search_field].to_s.upcase.strip
    code_search_field = params[:code_generic_search_field].to_s.upcase.strip
    description_search_field = params[:description_generic_search_field].to_s.upcase.strip
    condition = ""
    if !set_name_search_field.blank?
      condition += supply_non_empty_search_string('set_name', set_name_search_field)
    end
    if !code_search_field.blank?
      result = supply_non_empty_search_string('code', code_search_field)
      if !condition.blank? && !result.blank?
        condition += ' and '
        condition += result
      end
    end
    if !description_search_field.blank?
      result = supply_non_empty_search_string('description', description_search_field)
      if !condition.blank? && !result.blank?
        condition += ' and '
        condition += result
      end
    end
    condition
  end 
  
  
  def condition_for_fetching_a_crosswalk_record
    set_name_search_field = params[:set_name_search_field].to_s.upcase.strip
    code_search_field = params[:code_search_field].to_s.upcase.strip
    client_code_search_field = params[:client_code_search_field].to_s.upcase.strip
    site_code_search_field = params[:site_code_search_field].to_s.upcase.strip
    condition = ""
    unless set_name_search_field.blank? && code_search_field.blank? && client_code_search_field.blank? && site_code_search_field.blank?
      if !set_name_search_field.blank?
        condition += supply_non_empty_search_string('set_name', set_name_search_field)
      end
      if !code_search_field.blank?
        condition += ' and ' if !condition.blank?
        condition += supply_non_empty_search_string('code', code_search_field)
      end
      if !client_code_search_field.blank?
        condition += ' and ' if !condition.blank?
        condition += supply_non_empty_search_string('client_code', client_code_search_field)
      else
        condition += ' and ' if !condition.blank?
        condition += supply_empty_search_string('client_code')
      end
      if !site_code_search_field.blank?
        condition += ' and ' if !condition.blank?
        condition += supply_non_empty_search_string('site_code', site_code_search_field)
      else
        condition += ' and ' if !condition.blank?
        condition += supply_empty_search_string('site_code')
      end
    end
    condition
  end
  
  def supply_non_empty_search_string(criteria, search_field)
    condition = ""
    if !search_field.blank?
      case criteria
      when 'set_name'
        condition += "reason_code_set_names.name = '#{search_field}'"        
      when 'code'
        condition += "reason_code = '#{search_field}'"
      when 'description'
        condition += "reason_code_description = '#{search_field}'"        
      when 'client_code'
        condition += "clients.group_code = '#{search_field}'"
      when 'site_code'
        condition += "facilities.sitecode = '#{search_field}'"        
      end      
    end
    condition    
  end
  
  def supply_empty_search_string(criteria)
    condition = ""
    case criteria     
    when 'client_code'
      condition += "reason_codes_clients_facilities_set_names.client_id is NULL"
    when 'site_code'
      condition += "reason_codes_clients_facilities_set_names.facility_id is NULL"        
    end      
    condition    
  end

  def validate_before_create
    if params[:payer_id].present? && params[:reason_code_id].present?
      @payer = Payer.find(params[:payer_id])
      @reason_code = ReasonCode.find(params[:reason_code_id])
      return true
    end
    false
  end
  
  def set_attributes params
    @rccfsn.facility_id =  params[:facility_id]  
    @rccfsn.client_id = params[:client_id] 
    @rccfsn.crosswalk_level = params[:crosswalk_level]
    @rccfsn.sanitize_based_on_level_set
  end

  def prepare
    activity = JobActivityLog.new
    activity.current_user_id = current_user.id if current_user
  end
  
end
