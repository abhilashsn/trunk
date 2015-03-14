class ReasonCodesController < ApplicationController
  # GET /reason_codes
  # GET /reason_codes.xml
  layout "standard"
  require_role ["admin","supervisor","manager", "processor"]
  require_role "processor", :only => :list
  auto_complete_for :client_code, :adjustment_code
  auto_complete_for :hipaa_code, :hipaa_adjustment_code
  auto_complete_for :ansi_remark_code, :adjustment_code

  before_filter :prepare, :except => [:validate_reason_code_edit_with_user_confirmation]

  def index
    @back_page = params[:page_name]
    @rccfsns = ReasonCodesClientsFacilitiesSetName.
      select(" reason_codes_clients_facilities_set_names.*, reason_codes.reason_code as reason_code_name, \
                        reason_codes.id as reason_id, reason_codes.reason_code_description, payers.id as payer_id, payers.payer as payer_name"). \
      joins(" RIGHT JOIN reason_codes ON reason_codes.id = reason_codes_clients_facilities_set_names.reason_code_id
                       AND active_indicator = 1 \
                       INNER JOIN payers ON payers.reason_code_set_name_id = reason_codes.reason_code_set_name_id "). \
      where("payers.id = #{params[:id]} AND reason_codes.active = 1 AND reason_codes.replacement_reason_code_id IS NULL").
      includes(:hipaa_code, \
        {:reason_code => :ansi_remark_codes}). \
      paginate(:page => params[:page], :per_page => 30)
  end

  # GET /reason_codes/1
  # GET /reason_codes/1.xml
  def show
  end

  # GET /reason_codes/new
  # GET /reason_codes/new.xml
  def new
    @reason_code = ReasonCode.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reason_code }
    end
  end

  # GET /reason_codes/1/edit
  def edit
    @payer_id = params[:payer_id]
    @reason_code = ReasonCode.find(params[:id])
  end

  def edit_hipaa
    @payer_id = params[:payer_id]
    @reason_code = ReasonCode.find(params[:id])
  end

  def edit_ansi_remark_code
    @payer_id = params[:payer_id]
    @reason_code = ReasonCode.find(params[:id])
  end

  def edit_reasoncode_description
    @payer_id = params[:payer_id]
    @reason_code = ReasonCode.find(params[:id])
  end

  # POST /reason_codes
  # POST /reason_codes.xml
  def create
    hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
    client_code = params[:client_code][:adjustment_code]
    ansi_remark_code = params[:ansi_remark_code][:adjustment_code]
    if (params[:reason_code][:reason_code].blank? || params[:reason_code][:reason_code_description].blank?)
      flash[:notice] = 'Reason Code should not be blank'
      redirect_to :action => 'index',:id => params[:id]
    else
      reason_code = ReasonCode.new
      reason_code.reason_code = params[:reason_code][:reason_code]
      reason_code.reason_code_description = params[:reason_code][:reason_code_description]
      reason_code.new_code_status = "ACCEPT"
      hipaa_code_exists = HipaaCode.find(:first, :conditions => ["hipaa_adjustment_code = ?", hipaa_code], :select => ["id"]) unless hipaa_code.blank?
      client_code_exists = ClientCode.find(:first, :conditions => ["adjustment_code", client_code], :select => ["id"]) unless client_code.blank?
      ansi_remark_code_exists = AnsiRemarkCode.find(:first, :conditions => ["adjustment_code = ?", ansi_remark_code], :select => ["id"]) unless ansi_remark_code.blank?
      if ((hipaa_code_exists.blank? && hipaa_code != "") || (client_code_exists.blank? && client_code != "") || (ansi_remark_code_exists.blank? && ansi_remark_code != ""))
        flash[:notice] = 'Please Enter all valid Code'
        redirect_to :action => 'index',:id => params[:id]
      else
        if reason_code.save
          flash[:notice] = 'Reason Code was successfully created.'
          redirect_to :action => 'index',:id=>params[:id]
        else
          flash[:notice] = 'Failed creating Reason Code.'
          redirect_to :action => 'index',:id=>params[:id]
        end
      end

    end
  end

  # PUT /reason_codes/1
  # PUT /reason_codes/1.xml
  def update_client
    reason_code = ReasonCode.find(params[:id])
    client_code = params[:client_code][:adjustment_code]
    client_code_exists = ClientCode.find_by_adjustment_code(client_code) unless client_code.blank?
    if (client_code_exists.blank? or client_code == "")
      flash[:notice] = 'Please Enter a valid client Code'
      redirect_to :action => 'index',:id => params[:payer_id]
    else
      if reason_code.save
        flash[:notice] = 'Client Code was successfully updated.'
        redirect_to :action => 'index',:id => params[:payer_id]
      else
        flash[:notice] = 'Failed updating Client Code.'
        redirect_to :action => 'index',:id => params[:payer_id]
      end
    end
  end

  #  The method 'update_hipaa' associates a HIPAA code to the reason code
  def update_hipaa
    reason_code = ReasonCode.find(:first, :conditions => ["id = ?", params[:id]], :select => ["id"])
    hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
    hipaa_code_exists = HipaaCode.find(:first, :conditions => ["hipaa_adjustment_code = ?",hipaa_code], :select => ["id"]) unless hipaa_code.blank?
    if (hipaa_code_exists.blank? or hipaa_code == "")
      flash[:notice] = 'Please enter a valid HIPAA Code'
    else
      if reason_code.save
        flash[:notice] = 'HIPAA Code was successfully updated.'
      else
        flash[:notice] = 'Failed updating HIPAA Code.'
      end
    end
    if params[:view] == "new_reasoncode"
      redirect_to :controller => 'admin/payer', :action => 'manage_newly_added_codes'
    else
      redirect_to :action => 'index',:id => params[:payer_id]
    end
  end

  #  The method 'update_ansi_remark_code' associates a ANSI Remark Code to the reason code
  def update_ansi_remark_code
    reason_code = ReasonCode.find(:first, :conditions => ["id = ?", params[:id]], :select => ["id"])
    ansi_remark_code = params[:ansi_remark_code][:adjustment_code]
    ansi_remark_code_exists = AnsiRemarkCode.find(:first, :conditions => ["adjustment_code = ?",ansi_remark_code], :select => ["id"]) unless ansi_remark_code.blank?
    if reason_code.hipaa_code.blank?
      flash[:notice] = 'Please enter a valid HIPAA code for this reason code to enter ANSI Remark Code'
    elsif (ansi_remark_code_exists.blank? or ansi_remark_code == "")
      flash[:notice] = 'Please enter a valid ANSI Remark Code'
    else
      if reason_code.save
        flash[:notice] = 'ANSI Remark Code is successfully updated.'
      else
        flash[:notice] = 'Failed updating ANSI Remark Code.'
      end
    end
    if params[:view] == "new_reasoncode"
      redirect_to :controller => 'admin/payer', :action => 'manage_newly_added_codes'
    else
      redirect_to :action => 'index',:id => params[:payer_id]
    end
  end

  def update_reasoncode_description
    reason_code = ReasonCode.find(params[:id])
    reasoncode_description = params[:reason_code_description]
    if (reason_code.blank? or reasoncode_description == "")
      flash[:notice] = 'Please Enter a valid Reasoncode Description'
      redirect_to :action => 'index',:id => params[:payer_id]
    else
      reason_code.reason_code_description = reasoncode_description.strip
      if reason_code.save
        flash[:notice] = 'Reasoncode Description was successfully updated.'
        redirect_to :action => 'index',:id => params[:payer_id]
      else
        flash[:notice] = 'Failed updating Reasoncode Description.'
        redirect_to :action => 'index',:id => params[:payer_id]
      end
    end
  end

  # DELETE /reason_codes/1
  # DELETE /reason_codes/1.xml

  def delete_code
    payer_id = params[:payer_id]
    reason_code = ReasonCode.find(params[:id])
    reason_code.save
    reason_code.destroy

    flash[:notice] = 'Reason Code was successfully deleted.'
    redirect_to :action => 'index',:id => payer_id

  end

  def code_delete
    # payer = Payer.find(params["payer_id"])
    rccfsn = ReasonCodesClientsFacilitiesSetName.find(params["id"])
    reason_code = rccfsn.reason_code
    rccfsn.destroy    rescue nil
    reason_code.destroy rescue nil
    redirect_to :action => 'index',:id => params["payer_id"] # payer.id
  end

  def manage_codes
    @reason_code = ReasonCode.find(params[:reason_code_id])
    if !params[:payer_id].blank?
      @payer = Payer.find(params[:payer_id])
    else
      @payer = Payer.find_by_reason_code_set_name_id(@reason_code.reason_code_set_name_id)
    end
    @type = params["type"]
    @type = "global" if @type.blank?
    if params[:rccfsn_id].present?
      @rccfsn  = ReasonCodesClientsFacilitiesSetName.find(params[:rccfsn_id])
      if params["type"].blank?
        @type = @rccfsn.get_crosswalk_level.downcase
      end
    else
      @rccfsn  = ReasonCodesClientsFacilitiesSetName.new({ :reason_code_id => @reason_code.id })
    end
    if @type == "client" || @type == "facility"
      @clients = Client.select([:name,:id]).all
      @facilities ||= []
      if @type == "facility" && @rccfsn.id && @rccfsn.facility_id
        @facilities = Facility.where("client_id = ? ", @rccfsn.facility.client_id).select([:name,:id])
      end
    end
    @cross_walk_codes = {}
    if @rccfsn
      @cross_walk_codes = @rccfsn.get_codes_crosswalked
      if params[:from] == 'new_crosswalk'
        @remark_codes = []
      else
        @remark_codes, @remark_code_crosswalk_ids = @reason_code.get_remark_codes(@rccfsn.client_id, @rccfsn.facility_id)
      end
    end
  end

  def create_reason_code_and_map_multiple_codes
    payer = Payer.find(params["client_facility_payer_reasoncode"])
    if payer && payer.reason_code_set_name
      ReasonCode.create_reason_code_and_map_codes(payer, params)
    end
    flash[:notice] = "Sucessfully updated"
    redirect_to :action => "index",:id => payer.id
  end

  def validate_reason_code_edit_with_user_confirmation
    if params[:reason_code_id].present?
      reason_code = ReasonCode.find(params[:reason_code_id])
      if reason_code.present?
        is_user_acceptance_needed = validate_reason_code_edit(reason_code)
      end
    end
    is_user_acceptance_needed = is_user_acceptance_needed || false
    render :text => is_user_acceptance_needed.to_json
  end

  def validate_reason_code_edit(reason_code)    
    if params[:footnote_indicator].present?
      if reason_code.present?
        if params[:footnote_indicator] == 'true'
          footnote_indicator = true
        else
          footnote_indicator = false
        end
        is_user_acceptance_needed = reason_code.cleanup_for_editing_code_or_description(footnote_indicator,
          params[:reason_code].to_s, params[:reason_code_description].to_s, params[:user_acceptance], current_user.id)
      end
    end
    is_user_acceptance_needed || false
  end

  def map_multiple_code_for_reason_code
    begin
      if params[:payer_id].present?
        reason_code = ReasonCode.find(params[:reason_code_id])
        is_user_acceptance_needed = validate_reason_code_edit(reason_code)
        if !is_user_acceptance_needed
          if params["type"] == "client"
            map_multiple_code_for_reason_code_for_client
          elsif params["type"] == "facility"
            map_multiple_code_for_reason_code_for_facility
          else
            group_code = params[:crosswalk_codes][:group_code] if params[:crosswalk_codes] && params[:crosswalk_codes][:group_code].present?
            if params["id"].present?
              rccfsn = ReasonCodesClientsFacilitiesSetName.find(params["id"])
              unless rccfsn.update_attributes({:client_id=>nil, :facility_id=>nil, :hipaa_group_code => group_code})
                raise "Error While Saving Crosswalks\n" + rccfsn.errors.full_messages.join(", ")
              end
            else
              rccfsn = ReasonCodesClientsFacilitiesSetName.new({ :reason_code_id => reason_code.id, :hipaa_group_code => group_code })
              unless rccfsn.save
                raise "Error While Saving Crosswalks\n" + rccfsn.errors.full_messages.join(", ")
              end
            end
            rccfsn.associate_hippa_and_client_codes(params)
          end

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
          reason_code.associate_remark_codes(remark_codes_to_associate, associate_client_and_facility_ids,
            remark_code_crosswalked_and_client_and_facility_ids)
          flash[:notice] = "Successfully updated."
        else
          raise "Payer reference is not present."
        end
      end
    rescue Exception => e
      flash[:notice] = e.message
    end

    if params[:view] == "new_reason_code"
      filter_hash = params[:filter_hash].merge(:only_path => true)
      redirect_to :controller => "admin/payer", :action => "manage_newly_added_codes", :filter_hash => filter_hash
    elsif params["payer_id"].present?
      redirect_to :action => "index",:id => params["payer_id"]
    end
  end


  def map_multiple_code_for_reason_code_for_client
    @reason_code = ReasonCode.find(params[:reason_code_id])
    raise "Please Select a client, while trying to make client level mapping" if params[:client_id].empty?
    group_code = params[:crosswalk_codes][:group_code] if params[:crosswalk_codes] && params[:crosswalk_codes][:group_code].present?
    if params["id"].present?
      @rccfsn = ReasonCodesClientsFacilitiesSetName.find(params[:id])
      unless @rccfsn.update_attributes({:client_id=>params[:client_id], :facility_id=>nil, :hipaa_group_code => group_code})
        raise "Error While Saving Crosswalks\n" + @rccfsn.errors.full_messages.join(", ")
      end
    else
      @rccfsn = ReasonCodesClientsFacilitiesSetName.find(:first,
        :conditions => ["reason_code_id = #{@reason_code.id} AND client_id = #{params[:client_id]} AND active_indicator = 1"])
      if !@rccfsn.blank?
        raise "Crosswalked codes are already present for this level. Please edit the particular record from the list.\n"
      end
    end
    if @rccfsn.blank?
      @rccfsn = ReasonCodesClientsFacilitiesSetName.new({:reason_code_id =>@reason_code.id,
          :client_id => params[:client_id], :hipaa_group_code => group_code})
    end
    if @rccfsn.save
      @rccfsn.associate_hippa_and_client_codes(params)
    else
      raise "Error While Saving Crosswalks\n" + @rccfsn.errors.full_messages.join(", ")
    end
  end


  def map_multiple_code_for_reason_code_for_facility
    @reason_code = ReasonCode.find(params["reason_code_id"])
    raise "Please Select a Facility, while trying to make facility level mapping" if params[:facility_id].empty?
    group_code = params[:crosswalk_codes][:group_code] if params[:crosswalk_codes] && params[:crosswalk_codes][:group_code].present?
    if params["id"].present?
      @rccfsn = ReasonCodesClientsFacilitiesSetName.find(params[:id])
      unless @rccfsn.update_attributes({:client_id => nil, :facility_id => params[:facility_id], :hipaa_group_code => group_code})
        raise "Error While Saving Crosswalks\n" + @rccfsn.errors.full_messages.join(", ")
      end
    else
      @rccfsn = ReasonCodesClientsFacilitiesSetName.find(:first,
        :conditions => ["reason_code_id = #{@reason_code.id} AND facility_id = #{params[:facility_id]} AND active_indicator = 1"])
      if !@rccfsn.blank?
        raise "Crosswalked codes are already present for this level. Please edit the particular record from the list.\n"
      end
    end
    if @rccfsn.blank?
      @rccfsn = ReasonCodesClientsFacilitiesSetName.new({:reason_code_id => @reason_code.id,
          :facility_id => params[:facility_id], :hipaa_group_code => group_code})
    end
    if @rccfsn.save
      @rccfsn.associate_hippa_and_client_codes(params)
    else
      raise "Error While Saving Crosswalks\n" + @rccfsn.errors.full_messages.join(", ")
    end
  end




  def flash_notices(validate_hipaa_client_codes)
    if validate_hipaa_client_codes == "1"
      flash[:notice] = "Please provide valid ANSI,Client and Hipaa code"
    elsif validate_hipaa_client_codes == "2"
      flash[:notice] = "Please provide valid Client and Hipaa code"
    elsif validate_hipaa_client_codes == "3"
      flash[:notice] = "Please provide valid ANSI and Client code"
    elsif validate_hipaa_client_codes == "4"
      flash[:notice] = "Please provide valid ANSI and Hipaa code"
    elsif validate_hipaa_client_codes == "5"
      flash[:notice] = "Please provide valid Client code"
    elsif validate_hipaa_client_codes == "6"
      flash[:notice] = "Please provide valid Hipaa code"
    elsif validate_hipaa_client_codes == "7"
      flash[:notice] = "Please provide valid ANSI code"
    else
      flash[:notice] = "Codes are succesfully updated"
    end
  end

  def auto_complete_for_hipaa_code
    @hipaa_codes = HipaaCode.find(:all, :conditions => ["hipaa_adjustment_code like ?","%#{params[:hipaa][:code]}%"])
    render :layout => false
  end

  def auto_complete_for_client_code
    if $IS_PARTNER_BAC
      @client_codes = ClientCode.find(:all, :conditions => ["adjustment_code like ?","%#{params[:client][:code]}%"])
    end
    render :layout => false
  end

  def auto_complete_for_ansi_code
    @ansi_codes = AnsiRemarkCode.find(:all, :conditions => ["adjustment_code like ?","%#{params[:ansi][:code]}%"])
    render :layout => false
  end

  def facilities_for_client
    render :text => Facility.where("client_id = ?", params[:id]).select("id, name").to_json
  end

  def prepare
    activity = JobActivityLog.new
    activity.current_user_id = current_user.id if current_user
  end

end
