# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
require 'will_paginate/array' 

class Admin::UserController < ApplicationController
  require_role ["qa","admin","TL"], :except => [:change_password, :update_password]
  layout 'standard', :except => [:idle_processors, :change_password]
  auto_complete_for :user, :login

  # RAILS3.1 TODO
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # render new.rhtml
  def new
    @user = User.new
    @users_role =RolesUser.new
    @shifts = Shift.find(:all).map {|s| s.name}
    @roles = Role.find(:all).map {|r| r.name}
    @facilities = Facility.find(:all).map {|f| f.name}
    @client_facs = Partner.all_facilities
    @partners = Partner.all
    @clients = Client.all
  end
 
  def create
    #    logout_keeping_session!
    @user = User.new(params[:user])
    @user.file_837_report_permission = params[:user][:file_837_report_permission]
    @user.shift = Shift.find_by_name(params[:shift])
    @user.image_permision = params[:user][:image_permision]
    @user.image_835_permision = params[:user][:image_835_permision]
    @user.image_grid_permision = params[:user][:image_grid_permision]
    @user.claim_retrieval_permission = params[:user][:claim_retrieval_permission]
    @user.field_accuracy = params[:user][:field_accuracy]
    @user.rejected_eobs = params[:user][:rejected_eobs]
    @user.total_eobs = params[:user][:total_eobs]
    @user.allocation_status = 0
    @user.num_cre_errors = params[:user][:num_cre_errors]
    @user.location = params[:location]
    @user.employee_id = params[:user][:employee_id]
    @user.eligible_for_payer_wise_job_allocation = params[:user][:eligible_for_payer_wise_job_allocation]
    @user.fc_edit_permission = params[:user][:fc_edit_permission]
    @user.reset_password = true
    facility_objects = []
    facilities = []
    partners = []
    clients_fac = []
    roles = ["processor"]
    roles =  params[:role][:id] unless params[:role].blank?
    if roles.include? "partner"
      unless params[:partner].blank?
        partners = params[:partner][:id]
        partners.each do |partner|
          @user.partners << Partner.find(partner)
        end
      end
      params[:facility] = [] if roles.length == 1
    end

    if roles.include? "processor" and roles.include? "qa"
      flash[:notice] = 'Role should not be a combination of QA and Processor.'
      redirect_to :controller => 'user',:action => 'new'
    elsif ((roles.include? "client" and params[:client].blank?) or (roles.include? "facility" and params[:facility].blank?) or ((roles.include? "partner" and (partners.nil? or params[:partner].blank?))))
      flash[:notice] = 'Partner/Client/Facility name should be specified for Partner/Client/Facility users'
      redirect_to :controller => 'user',:action => 'new'
    else
      success = @user && @user.save
      if success && @user.errors.empty?
        access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
        RevremitMailer.notify_fc_edit_permission_grant(@user, current_user, access_info).deliver if @user.fc_edit_permission
        if roles.include? "client"
          unless params[:client].blank?
            clients_fac = params[:client][:id]
            clients_fac.each do |client|
              @user.clients << Client.find(client)
            end
            @user.save
          end
        end
        unless params[:facility].blank?
          facilities  =  params[:facility][:id]
          facilities.each do |facility|
            @user.facilities << Facility.find(facility)
          end
          @user.save
        end
        # @user = User.new(params[:user])
        # @user.user_id = @user.id
        # @user.userid = params[:user][:login]
        # @user.password = params[:user][:password]
        # @user.shift = Shift.find_by_name(params[:shift])
        # @user.save
        roles.each do |role|
          role_user = Role.find_by_name(role)
          @users_role = RolesUser.new
          @users_role.role_id = role_user.id
          @users_role.user_id = @user.id
          @users_role.save
        end
        # Protects against session fixation attacks, causes request forgery
        # protection if visitor resubmits an earlier form using back roles
        # button. Uncomment if you understand the tradeoffs.
        # reset session
        #        self.current_user = @user # !! now logged in
        #        redirect_back_or_default('/users/list')
        flash[:notice] = 'User was successfully created.'
        redirect_to :controller => 'user',:action => 'index'
      else
        flash[:notice]  = "Failed creating users"
        @shifts = Shift.find(:all).map {|s| s.name}
        @roles = Role.find(:all).map {|r| r.name}
        @facilities = Facility.find(:all).map {|f| f.name}
        @client_facs = Partner.all_facilities
        @partners = Partner.all
        @clients = Client.all
        render :controller => 'user', :action => 'new'
      end
    end
  end

  def index
    relation_include = [ {:roles_users => :role}]
    # Filtering code below
    filter_field = params[:to_find]
    filter_field.strip! unless filter_field.nil?
    if filter_field.nil?
      @users = User.where(" users.is_deleted = 0").includes(relation_include).paginate(:page => params[:page])
    else
      filter_field = filter_field.to_s.upcase
      filter_by = params[:criteria]
      flash[:notice] = nil
      case filter_by
      when 'Name'
        conditions = "users.name like ? and users.is_deleted = 0"
      when 'User ID'
        conditions = "users.login like ? and users.is_deleted = 0"
      when 'Status'
        status = []
        if "ONLINE".match(filter_field.upcase)
          status << 1
        end
        if "OFFLINE".match(filter_field.upcase)
          status << 0
        end
        conditions = "users.login_status like ? and users.is_deleted = 0"
        if status.size == 1
          filter_field = status.first
        end
        if status.size == 2
          filter_field = status.second
          conditions = "(users.login_status= '#{status.first}' OR  users.login_status like ?) and users.is_deleted = 0"
        end
      when 'Role'
        conditions = "roles.name like ? and users.is_deleted = 0"
      when 'Remark'
        conditions = "users.remark like ? and users.is_deleted = 0"
      end
      @users = User.where(conditions, "%#{filter_field}%").includes(relation_include).paginate(:page => params[:page], :per_page => 30)
      if @users.size == 0
        flash[:notice] = "No user found for '#{filter_by}' as '#{params[:to_find]}'"
      end
    end

    # For AJAX requests, render the partial and disable the layout
    if request.xml_http_request?
      render :partial => "users_list", :layout => false
    end
  end

  def show
    @users = User.where(["is_deleted = 0 and users.id = ?",params[:id]]).paginate(:page => params[:page])
  end

  def edit
    @role_array=""
    @facility_array=[]
    @user = User.find(params[:id])
    @partner_array = @user.partners.collect(&:id)
    @client_array = @user.clients.collect(&:id)
    @facility_array = @user.facilities.collect(&:id)
    @shifts = Shift.find(:all).map {|s| s.name}
    @roles = Role.find(:all).map {|r| r.name}
    @facilities = Facility.find(:all).map {|f| f.name}
    @client_facs = Partner.all_facilities
    @partners = Partner.all
    @clients = Client.all
    @selected = @user.shift.name
    @selected_location = @user.location 
    #role_user = RolesUser.find(:all,:conditions=>["user_id=?",@user.id],:select => "distinct role_id")
    
    unless @user.roles.empty?
      @user.roles.map{|role| @role_array << role.name}
    end
    user_facilities = FacilitiesUser.find(:all,:conditions=>["user_id=?",@user.id])
    if !user_facilities.nil?
      user_facilities.each do |r|
        if !r.facility.nil?
          @facility_array << r.facility.id
        else
          @facility_array <<[]
        end
      end
    end
    if @user.image_permision=='1'
      @image = true
    else
      @image = false
    end
    if @user.image_835_permision=='1'
      @image_835 = true
    else
      @image_835 = false
    end
    if @user.image_grid_permision=='1'
      @image_grid = true
    else
      @image_grid = false
    end
    if @user.claim_retrieval_permission == '1'
      @claim_retrieval = true
    else
      @claim_retrieval = false
    end
    if @user.batch_status_permission == '1'
      @batch_status_grid = true
    else
      @batch_status_grid = false
    end
    
    if @user.file_837_report_permission == '1'
      @file_837_report_permission = true
    else
      @file_837_report_permission = false
    end
    
    @password = @user.password
    @user.password = nil
    @page = params[:page]
  end

  def update
    @user = User.find(params[:id])    
    @user.update_attributes(params[:user])

    if params[:user][:password].present?
      @user.reset_password = true
      if @user.failed_attempts > 0 || @user.locked_at.present?
        @user.locked_at = nil
        @user.failed_attempts = 0
      end
    end    
    @user.shift = Shift.find_by_name(params[:shift])
    @user.image_permision = params[:user][:image_permision]
    @user.image_835_permision = params[:user][:image_835_permision]
    @user.image_grid_permision = params[:user][:image_grid_permision]
    @user.claim_retrieval_permission = params[:user][:claim_retrieval_permission]
    @user.file_837_report_permission = params[:user][:file_837_report_permission]
    @user.field_accuracy = params[:user][:field_accuracy]
    @user.rejected_eobs = params[:user][:rejected_eobs]
    @user.total_eobs = params[:user][:total_eobs]
    @user.num_cre_errors = params[:user][:num_cre_errors]
    @user.location = params[:location]
    @user.employee_id = params[:user][:employee_id]
    @user.eligible_for_payer_wise_job_allocation = params[:user][:eligible_for_payer_wise_job_allocation]
    @user.fc_edit_permission = params[:user][:fc_edit_permission]
    facility_objects = []
    facilities = []
    roles = ["processor"]
    roles = params[:role][:id] unless params[:role].blank?
    partners = []  

    password = params[:user][:password]
    if roles.include? "partner"
      unless params[:partner].blank?        
        partners = params[:partner][:id]
        if partners.present?
          @user.partners.delete_all if @user.partners
          partners.each do |partner|
            @user.partners << Partner.find(partner)
          end
        end
      end
      params[:facility] = [] if roles.length == 1
    end
    
    if roles.include? "client"
      unless params[:client].blank?
        clients_fac = params[:client][:id]
        if clients_fac.present?
          @user.clients.delete_all unless @user.clients.blank?
          clients_fac.each do |client|
            @user.clients << Client.find(client)
          end
        end
      end
      params[:facility] = [] if roles.length == 1
    end

    unless params[:facility].blank?
      facilities  =  params[:facility][:id]
      if facilities.present?
        @user.facilities.delete_all unless @user.facilities.blank?
        facilities.each do |facility|
          facility_objects << Facility.find(facility)
        end
        @user.facilities << facility_objects
      end
    end
    if ((roles.include? "facility" and (facilities.nil?or facilities.blank?))) or (roles.include? "client" and params[:client].blank?) or ((roles.include? "partner" and (partners.nil? or partners.blank?)))
      flash[:notice] = 'Partner/Client/Facility name should be specified for Partner/Client/Facility users'
      redirect_to :controller => 'user', :action => 'edit'
    elsif roles.include? "processor" and roles.include? "qa"
      flash[:notice] = 'Role should not be a combination of QA and Processor.'
      redirect_to :controller => 'user', :action => 'edit'
    else
      changed_fc_edit_permission = @user.fc_edit_permission_changed?
      success = @user && @user.save
      if success && @user.errors.empty?
        access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
        RevremitMailer.notify_fc_edit_permission_grant(@user, current_user, access_info).deliver if @user.fc_edit_permission && changed_fc_edit_permission
        user = User.find(params[:id])
        user.shift = Shift.find_by_name(params[:shift])
        user.save
             
        RolesUser.destroy_all ["user_id=?", @user.id]
        
        roles.each do |role|
          role_user = Role.find_by_name(role)
          users_role =RolesUser.new
          users_role.role_id = role_user.id
          users_role.user_id = @user.id
          users_role.save
        end

        # Protects against session fixation attacks, causes request forgery
        # protection if visitor resubmits an earlier form using back
        # button. Uncomment if you understand the tradeoffs.
        # reset session
        #        self.current_user = @user # !! now logged in
        #        redirect_back_or_default('/users/list')
        User.update_password_history(@user.id, password)
        
        flash[:notice] = 'User was successfully updated.'
        redirect_to :controller => 'user', :action => 'index'
      else
        flash[:notice] = "Failed in Updating user"
        @shifts = Shift.find(:all).map {|s| s.name}
        @roles = Role.find(:all).map {|r| r.name}
        @facilities = Facility.find(:all).map {|f| f.name}
        @client_facs = Partner.all_facilities
        @partners = Partner.all
        @clients = Client.all
        @partners = Partner.all
        @selected = @user.shift.name
        @selected_location = @user.location
        @role_array=""
        unless @user.roles.empty?
          @user.roles.map { |role| @role_array << role.name }
        end
        render :controller => 'user', :action => 'edit', :id => @user.id
      end
    end
  end
  
  def change_password
    layout = 'standard'
    if current_user.reset_password
      layout = 'reset_password'
    end
    render :layout => layout
  end

  def update_password
    @user = current_user
    if request.post?
      if (params[:user])
        result_of_validation = true
        password = params[:user][:password].strip
        password_confirmation = params[:user][:password_confirmation].strip
        if password.blank?
          result_of_validation = false
          flash[:notice] = "Password is mandatory."
        end
        if result_of_validation && password_confirmation.blank?
          result_of_validation = false
          flash[:notice] = "Password confirmation is mandatory."
        end
        if result_of_validation
          result_of_validation = (password == password_confirmation)
          flash[:notice] = "Password confirmation not matching."
        end
        if result_of_validation
          if @user.failed_attempts > 0 || @user.locked_at.present?
            @user.locked_at = nil
            @user.failed_attempts = 0
          end
          @user.reset_password = false
          result_of_validation = @user.update_attributes(params[:user])
          
          if result_of_validation
            sign_in(@user, :bypass => true)
            flash[:notice] = "Password changed successfully."
            User.update_password_history(current_user.id, password)
            redirect_to :controller => '/dashboard', :action => :index
          else
            flash[:notice] = "Failed changing Password."
            flash[:notice] += @user.errors[:base].join(', ') if @user.errors
          end
        end
        if not result_of_validation
          redirect_to :action => "change_password"
        end
      end
    end
  end

  def destroy
    user = User.find(params[:id])
    if user.login == 'admin'
      flash[:notice] = 'Default admin cannot be deleted.'
    else
      user.destroy
    end
    redirect_to :action => 'index'
  end

  def delete_users
    users = params[:users_to_delete]
    users.delete_if do |key, value|
      value == "0"
    end
    @flag=0
    flash[:notice1] = ""
    flash[:notice] = ""
    users.keys.each do |id|
      if id == '1'
        @flag = 1
        flash[:notice1] = 'The default Admin user cannot be deleted.'
      else
        user = User.find(id)
        roleusers = user.roles_users
        role = ""
        roleusers.each do |ru|
          role = ru.role.name
        end
        
        jobs = Job.find_all_by_processor_id(user.id)
        jobs.each do |j|
         
          if role.downcase == 'processor'
            if j.processor_status == ProcessorStatus::ALLOCATED
              j.processor_status = ProcessorStatus::NEW
              j.processor = nil
            elsif j.processor_status == ProcessorStatus::ADDITIONAL_JOB_REQUESTED
              j.processor = nil
            end
          elsif role.downcase == 'qa'
            if j.qa_status == QaStatus::ALLOCATED
              j.qa_status = QaStatus::NEW
              j.qa = nil
            end
          end

          if j.processor_status != ProcessorStatus::ADDITIONAL_JOB_REQUESTED
            if j.qa_status == QaStatus::NEW
              if j.processor_status == ProcessorStatus::NEW
                j.job_status = JobStatus::NEW
              elsif  j.processor_status == ProcessorStatus::ALLOCATED
                j.job_status = JobStatus::ALLOCATED
              elsif j.processor_status == ProcessorStatus::COMPLETED
                j.job_status = JobStatus::COMPLETED
              end
            elsif  j.qa_status == QaStatus::COMPLETED
              if j.processor_status == ProcessorStatus::COMPLETED
                j.job_status = JobStatus::COMPLETED
              elsif j.processor_status == ProcessorStatus::ALLOCATED
                j.job_status = JobStatus::ALLOCATED
              end
            else
              j.job_status = JobStatus::PROCESSING
            end
          end
          j.save
        end
        user.is_deleted = true
        user.login_status = OFFLINE
        user.save(:validate=>false)
        if (@flag==1)
          flash[:notice] = "Deleted #{users.keys.size-1} user(s)."
        else
          flash[:notice] = "Deleted #{users.keys.size} user(s)."
        end
      end
    end
    if (@flag==1)
      if(flash[:notice]==nil)
        flash[:notice]=flash[:notice]+""+flash[:notice1]
      else
        if users.keys.size !=1
          flash[:notice]="Deleted #{users.keys.size-1} users.<BR>"+flash[:notice1]
        else
          flash[:notice]=flash[:notice1]
        end
      end
    end

    if users.keys.size == 0
      flash[:notice] = "Please select atleast one user to delete."
    end
    redirect_to :action => 'index'
  end

  def list_jobs
    @user = User.find(params[:id])
    @jobs = Job.find(:all, :conditions => "processor_id = #{@user.id}",
      :joins => "left join batches on batch_id = batches.id" )

    if @jobs.size == 0
      flash[:notice] = "No job has been assigned to the processor!"
      redirect_to :action => 'index'
    end #if
  end

  def list_processor_occupancy
    time_minus_12_hrs = Time.now - 12.hours

    @users = User.select(" users.id as id \
                ,  users.login as login \
                , users.field_accuracy as field_accuracy \
                , COUNT(jobs.id) AS allocated_jobs \
                , COUNT(CASE WHEN processor_status = '#{ProcessorStatus::COMPLETED}'
                        THEN jobs.id ELSE NULL END) AS completed_jobs \
                , SUM(CASE WHEN processor_status = '#{ProcessorStatus::COMPLETED}'
                      THEN jobs.count ELSE 0 END) AS completed_eobs").
      where(["jobs.processor_flag_time >= ? and
                    jobs.processor_id = users.id and
                    roles.name = 'processor' and
                    users.login_status = #{ONLINE}", time_minus_12_hrs]).
      joins("LEFT OUTER JOIN roles_users ON roles_users.user_id = users.id
                   LEFT OUTER JOIN roles ON roles.id = roles_users.role_id
                   LEFT OUTER JOIN jobs ON jobs.processor_id = users.id").
      group("jobs.processor_id")

  end

  def list_qa_occupancy
    time_minus_12_hrs = Time.now - 12.hours

    @users = User.select(" users.id as id \
                ,  users.login as login \
                , users.field_accuracy as field_accuracy \
                , COUNT(jobs.id) AS allocated_jobs \
                , COUNT(CASE WHEN qa_status = '#{QaStatus::COMPLETED}'
                        THEN jobs.id ELSE NULL END) AS completed_jobs").
      where(["jobs.qa_flag_time >= ? and
                    jobs.qa_id = users.id and
                    roles.name.upcase = 'QA' and
                    users.login_status = #{ONLINE}", time_minus_12_hrs]).
      joins("LEFT OUTER JOIN roles_users ON roles_users.user_id = users.id
                   LEFT OUTER JOIN roles ON roles.id = roles_users.role_id
                   LEFT OUTER JOIN jobs ON jobs.qa_id = users.id").
      group("jobs.qa_id")

  end
  
  #lists all members for a particular team leader
  def assign_members
    @tl = User.find(params[:id])
    @all_processors = User.find(:all, :conditions => "role = 'Processor' and
       (teamleader_id != #{@tl.id} and
        teamleader_id not in (select id from users where role = 'TL') or teamleader_id is null)").
      paginate(:page => params[:page], :per_page => 2)

  end
  
  #allocates/assigns processors to a team leader
  def allocate_members
    @tl = User.find(params[:tl])
    selected_processors = params[:users_to_assign]
    selected_processors = selected_processors.delete_if {|k, v| v=="0"}
    selected_processors.each {|k, v| u = User.find(k); u.teamleader = @tl; u.save }
    redirect_to :action => 'assign_members', :id => @tl
  end
  
  #deallocates/removes members from team leader's team
  def remove_members
    @tl = User.find(params[:tl])
    selected_processors = params[:users_to_remove]
    selected_processors = selected_processors.delete_if {|k, v| v=="0"}
    selected_processors.each {|k, v| u = User.find(k); u.teamleader = nil; u.save }
    redirect_to :action => 'assign_members', :id => @tl
  end
  
  def list_members
    time_minus_24_hrs = Time.now - 24.hours

    @members = User.select(" users.id as id \
                ,  users.login as login \
                , users.field_accuracy as field_accuracy \
                , COUNT(jobs.id) AS allocated_jobs \
                , COUNT(CASE WHEN processor_status = '#{ProcessorStatus::COMPLETED}'
                        THEN jobs.id ELSE NULL END) AS completed_jobs \
                , SUM(CASE WHEN processor_status = '#{ProcessorStatus::COMPLETED}'
                      THEN jobs.count ELSE 0 END) AS completed_eobs").
      where(["jobs.processor_flag_time >= ? and
                    jobs.processor_id = users.id and
                    roles.name = 'processor'", time_minus_24_hrs]).
      joins("LEFT OUTER JOIN roles_users ON roles_users.user_id = users.id
                   LEFT OUTER JOIN roles ON roles.id = roles_users.role_id
                   LEFT OUTER JOIN jobs ON jobs.processor_id = users.id").
      group("jobs.processor_id")
  end
  
  #lists all processors for a given time range(default: current day)
  def processor_report
    from = Date.rr_parse(params[:date_from], true).to_s unless params[:date_from].nil?
    to = Date.rr_parse(params[:date_to], true).to_s unless params[:date_to].nil?
    
    #these are required to retain values in text fields
    @date_from = from
    @date_to = to
    @userid = params[:userid]
    
    if not from.blank?
      time_from = (from + " 00:00:00").to_time
      if not to.blank?
        time_to = (to + " 23:59:59").to_time
      else
        time_to = time_from + 1.days
      end
    elsif not to.blank?
      time_to = (to + " 23:59:59").to_time
      time_from = time_to - 1.days
    else
      time_to = Time.now
      time_from = time_to - 24.hours
    end
    @users = filter_processor_report(params[:userid], time_from, time_to)
    
  end
  
  #being used by processor report to get final list of users
  def filter_processor_report(user, time_from, time_to)
    relation_include = [ {:roles_users=>:role} ,:processor_jobs]
    #    user.blank? ? condition = "" : condition = " and users.login like '%#{user}%'"
    #    users = User.paginate(:all,:conditions => ["jobs.processor_flag_time >= ? and
    #                                            jobs.processor_flag_time <= ? and
    #                                            jobs.processor_id = users.id and
    #                                            roles.name = 'processor'#" + condition, time_from, time_to],
    #                            :include => relation_include,
    #                            :group => "jobs.processor_id",:page => params[:page], :per_page => 50)
    #       users = User.find(:all,:conditions => ["jobs.processor_flag_time >= ? and
    #                                            jobs.processor_flag_time <= ? and
    #                                            jobs.processor_id = users.id and
    #                                            role = 'Processor'" + condition, time_from, time_to],
    #                            :include => :processor_jobs,
    #                            :group => "jobs.processor_id")
    conditions = "jobs.processor_id = users.id AND roles.name = 'processor'"
    conditions += " AND users.login like '%#{user}%'" unless user.blank?
    users = User.includes(relation_include).where(conditions).paginate(:page => params[:page], :per_page => 50)
    
    users.each do |user|
      jobs = user.processor_jobs
      jobs.select {|job|
        (!job.processor_flag_time.blank? && job.processor_flag_time >= time_from &&
            job.processor_flag_time <= time_to && job.processor_status == ProcessorStatus::COMPLETED)}
      user['completed_jobs'] = jobs.size

      eob_count = 0
      jobs.each do |job|
        eob_count = eob_count + job.count
      end
      user['completed_eobs'] = eob_count
    end
  end
  
  #lists all the facilities for a particular processor for a given time range
  def processor_facility_jobs
    unless params[:date_from].nil?
      @date_from = params[:date_from]
      @date_to = params[:date_to]
      time_from = (params[:date_from] + " 00:00:00").to_time
      #time_from = convert_to_est_time(time_from)
      time_to = (params[:date_to] + " 23:59:59").to_time
      #time_to = convert_to_est_time(time_to)
    else
      time_to = Time.now
      time_from = time_to - 1.days
      @date_from = Date.strptime(time_from.strftime("%m/%d/%y"), "%m/%d/%y")
      @date_to = Date.strptime(time_to.strftime("%m/%d/%y"), "%m/%d/%y")
      time_from = (@date_from.to_s + " 00:00:00").to_time
      time_to = (@date_to.to_s + " 23:59:59").to_time
    end
    
    user = User.find(params[:user])
    facility_id = params[:id].to_i unless params[:id].nil?
    @facility_jobs = user.facility_jobs(time_from, time_to)
    
    unless params[:id].nil?
      @jobs = list_facility_jobs(time_from, time_to, facility_id, params[:user].to_i)
    else
      @jobs = list_facility_jobs(time_from, time_to, @facility_jobs[0].id.to_i, params[:user].to_i)
    end

  end
  
  def productivity_report
    unless params[:date_from].nil?
      @date_from = params[:date_from]
      @date_to = params[:date_to]
      time_from = (params[:date_from] + " 00:00:00").to_time
      time_to = (params[:date_to] + " 23:59:59").to_time
    else
      time_to = Time.now
      time_from = time_to - 1.days
      @date_from = time_from.strftime("%m/%d/%y")
      @date_to = time_to.strftime("%m/%d/%y")
      time_from = (@date_from.to_s + " 00:00:00").to_time
      time_to = (@date_to.to_s + " 23:59:59").to_time
    end
    
    @all_facilities = {}
    
    Facility.find(:all).each do |f|
      @all_facilities[f.name] = f.id
    end

    @all_facilities = @all_facilities.sort_by {|name, id| name}

    @selected_facilities = []
    facility_condition = ""
    unless params[:facilities].nil?
      @selected = params[:facilities]
      # TODO: Review this. I don't think it is producing the right output (HCR)
      @selected.each do |sf|
        @selected_facilities << sf.to_i
      end
      @selected = @selected.join(", ")
      facility_condition = " and facilities.id in (#{@selected})"
    end

    filter = Filter.new
    filter.multiple [BatchStatus::COMPLETED], 'batches.status'
    filter.multiple  @selected_facilities, 'facilities.id' unless @selected_facilities.empty?
    @userid = params[:userid] || ""
    userid_array = @userid.split(',').map {|s| s.strip}
    filter.multiple userid_array, 'users.userid' unless userid_array.empty?
    @batchid = params[:batchid] || ""
    batchid_array = @batchid.split(',').map {|s| s.strip}
    filter.multiple batchid_array, 'batches.batchid' unless batchid_array.empty?
    @payid = params[:payid] || ""
    payid_array = @payid.split(',').map {|s| s.strip}
    filter.multiple payid_array, 'payers.payid' unless payid_array.empty?
    
    filter.less time_to.to_s(:db), 'jobs.processor_flag_time'
    filter.great time_from.to_s(:db), 'jobs.processor_flag_time'
    
    logger.debug "Filter conditions: #{filter.conditions}"

    @jobs = Job.paginate(:all, :include => [{:batch => :facility}, :payer, :processor], :conditions => filter.conditions, :page => params[:page])
    
    logger.debug "Pressed #{params[:commit]}"
    
    if params[:commit] == "Export" then
      if @jobs.empty? then
        flash[:notice] = "No productivity info to export"
      else
        e = Excel::Workbook.new
        jobs_array = Array.new
        jobs = Job.find(:all, :include => [{:batch => :facility}, :payer, :processor], :conditions => filter.conditions)
        jobs.each do |j|
          h = Hash.new
          h["Processor"] = j.processor.nil? ? "Unknown" : j.processor.userid
          h["Batch ID"] = j.batch.batchid
          h["Batch Date"] = j.batch.date
          h["Site Number"] = j.batch.facility.sitecode
          h["Facility Name"] = j.batch.facility.name
          h["Check Number"] = j.check_number
          h["EOBs"] = j.count
          h["Payer"] = "#{j.payer.payer}(#{j.payer.supply_payid})"
          h["Shift"] = j.processor_complete_shift
          h["Job Completion Time"] = j.processor_flag_time.strftime("%m/%d/%y %H:%M")
          jobs_array << h
        end
        e.addWorksheetFromArrayOfHashes("Productivity", jobs_array)
        
        # Cribbed from CSV examples. Not sure it is ideal.
        if request.env['HTTP_USER_AGENT'] =~ /msie/i
          headers['Pragma'] = 'public'
          headers['Content-Type'] = "application/vnd.ms-excel"
          headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
          headers['Content-Disposition'] = "attachment; filename=\"processor_productivity.xls\""
          headers['Expires'] = "0"
        else
          headers['Content-Type'] = "application/vnd.ms-excel"
          headers["Content-Disposition"] = "attachment; filename=\"processor_productivity.xls\""
        end

        render_text(e.build)
      end
    end
  end
  
  #being used by processor_facility_jobs to get list of jobs for a particular
  #user and facility
  def list_facility_jobs(time_from, time_to, id, user_id)
    time_from = time_from.strftime("%Y-%m-%d %H:%M:%S")
    time_to = time_to.strftime("%Y-%m-%d %H:%M:%S")
    jobs = []
    Facility.find(id).batches.each do |b|
      found_jobs = b.jobs.find(:all,
        :conditions => "processor_flag_time >= '#{time_from}' " +
          "and processor_flag_time <= '#{time_to}' " +
          "and processor_id = #{user_id}").
        paginate(:page => params[:page], :per_page => 50)
      found_jobs.each {|j| jobs << j}
    end
    return jobs
  end

  def paginate_collection(collection, options = {})
    default_options = {:per_page => 30, :page => 1}
    options = default_options.merge options
    pages = Paginator.new self, collection.size, options[:per_page], options[:page]
    first = pages.current.offset
    last = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end
  
  # Listing Productivity Report
  def joblist
    @user1=[]
    @users = ""
    puts params[:criteria]
    puts params[:time_difference]
    if ((params[:date_from].blank?) and (params[:date_to].blank?))
      @user=Job.find(:all, :conditions => "users.is_deleted != 1 and
              processor_status = '#{ProcessorStatus::COMPLETED}' and time_taken is not null",
        :select => "processor_id processor_id,sum(count) count,((sum(time_taken)/60)/sum(count)) time ",
        :group => "processor_id",
        :order => "time",
        :joins => "inner join users on users.id=jobs.processor_id")
      @user.each do|p|
        p['processor_id']= p.processor_id
        p['count']= p.count
        p['time'] = p.time
        p['totalcount'] = EobQa.count(:all,:conditions=>"processor_id=#{p.processor_id}")
        p['incorrect'] = EobQa.count(:all,:conditions=>"processor_id=#{p.processor_id} and total_incorrect_fields>0")
        @user1 << p
      end
    else if ((params[:date_from].blank?) and (not params[:date_to].blank?))
        flash[:notice] = "From Date Mandatory"
        @user='nil'
        @users = @user.paginate(:page => params[:page], :per_page => 30)
        redirect_to :controller=>'user',:action => 'joblist'
      else if ((not params[:date_from].blank?) and (params[:date_to].blank?))
          flash[:notice] = "To Date Mandatory"
          @user='nil'
          @users = @user.paginate(:page => params[:page], :per_page => 30)
          redirect_to :controller=>'user',:action => 'joblist'
        else if ((not params[:date_from].blank?) and (not params[:date_to].blank?))
            time_from = (params[:date_from] + " 00:00:00").to_time
            session[:fromtime]= time_from
            time_to = (params[:date_to] + " 23:59:59").to_time
            time_to1 = (params[:date_to] + " 00:00:00").to_time
            session[:totime]= time_to1
            #For EST to IST conversion minus 10h and 30 min from from date and to_date
            if(params[:criteria]=='IST')
              @user = Job.find(:all, :conditions => "processor_status in ('#{ProcessorStatus::COMPLETED}')
                      and processor_flag_time >= TIMESTAMPADD(hour,-#{params[:time_difference]},
                      '#{time_from.to_date}') and processor_flag_time < TIMESTAMPADD(hour,-#{params[:time_difference]},
                      '#{(time_to + 1.days).to_date}') and time_taken is not null",
                :select => "processor_id processor_id, sum(count) count, ((sum(time_taken)/60)/(sum(count))) time",
                :group => "processor_id",
                :order => "time")
            else
              @user = Job.find(:all, :conditions => "processor_status in ('#{ProcessorStatus::COMPLETED}')
                      and processor_flag_time >= '#{time_from.to_date}'
                      and processor_flag_time < '#{(time_to + 1.days).to_date}' and time_taken is not null",
                :select => "processor_id processor_id, sum(count) count, ((sum(time_taken)/60)/(sum(count))) time",
                :group => "processor_id",
                :order => "time")
            end
            @user.each do|p|
              p['processor_id']= p.processor_id
              p['count']= p.count
              p['time'] = p.time
              p['totalcount'] = EobQa.count(:all,:conditions=>"processor_id=#{p.processor_id} and time_of_rejection>='#{time_from.to_date}' and time_of_rejection<='#{(time_to+1.days).to_date}'")
              p['incorrect'] = EobQa.count(:all,:conditions=>"processor_id=#{p.processor_id} and total_incorrect_fields>0 and time_of_rejection>='#{time_from.to_date}' and time_of_rejection<'#{(time_to+1.days).to_date}'")
              @user1 << p
            end
          end

        end
      end
    end
    @users = @user1.paginate(:page => params[:page], :per_page => 30)

  end
  #accuracy Report

  def accuracy_report
  
  
    @procid=params[:procid]
    if ((session[:fromtime].blank?) and  (session[:totime].blank?))
      @p=[]
    
      @first = Job.find(:all, :conditions => "processor_status = '#{ProcessorStatus::COMPLETED}'
                  and processor_id = #{params[:procid]}",
        :select => " min(processor_flag_time) processor_flag_time")
      @last = Job.find(:all, :conditions => "processor_status = '#{ProcessorStatus::COMPLETED}'
                  and processor_id = #{params[:procid]}",
        :select => " max(processor_flag_time) processor_flag_time1")
    
      @first.each do |p|
        @firsttime= p.processor_flag_time.to_time
        @firsttime1= p.processor_flag_time.to_time
      end
      @last.each do |p|
        @lasttime= p.processor_flag_time1.to_time
      
      end
      while(@firsttime < @lasttime)
      
        time = Job.find(:all, :conditions => "processor_status = '#{ProcessorStatus::COMPLETED}'
            and processor_id = #{params[:procid]} and processor_flag_time >= '#{@firsttime.to_date}'
            and processor_flag_time <= '#{(@firsttime+7.days).to_date}' and time_taken is not null",
          :select => "((sum(time_taken)/60)/(sum(count))) time, processor_flag_time",
          :group => "processor_id")
        @p<<time
        @firsttime = @firsttime + 7.days
      
      
      end
    else
      @p=[]
      @firsttime= session[:fromtime].to_time
      @firsttime1= session[:fromtime].to_time
      while(@firsttime.to_date < session[:totime].to_date)
        puts @firsttime.to_date
        time =Job.find(:all, :conditions => "processor_status = '#{ProcessorStatus::COMPLETED}'
              and processor_id = #{params[:procid]} and processor_flag_time >= '#{@firsttime.to_date}'
              and processor_flag_time < '#{(@firsttime+7.days).to_date}' and time_taken is not null ",
          :select => "((sum(time_taken)/60)/(sum(count))) time, processor_flag_time",
          :group => "processor_id")
        @p<<time
        @firsttime = (@firsttime + 7.days)
      
      
      end
    end
    session[:fromtime]=nil
    session[:totime] =nil
  end
  
  #  Method to create or update the client to user association.
  #  For each client selected, this method updates the records in clients_users
  #  table with the given conditions and attributes. If no records to update
  #  then this method creates new record with the given attributes.
  def create_or_update_facilities_to_users
    processor_id = params[:processor]
    selected_facilities = params[:facilities_to_update]
    facility_ids_to_update = []
    facility_ids_to_create = []
    selected_facilities = selected_facilities.delete_if {|key, value| value == "0"}
    if params[:option] == 'Add to allocation'
      allocation_flag = true
    elsif params[:option] == 'Remove from allocation'
      allocation_flag = false
    end
    selected_facilities.each do |selected_ids, value|
      facility_user = selected_ids.split(',')
      facility_id = facility_user[0]
      facility_user_id = facility_user[1]
      facility_ids_to_create << facility_id if facility_user_id.blank?
      facility_ids_to_update << facility_id unless facility_user_id.blank?
    end
    FacilitiesUser.update_facilities_to_user(facility_ids_to_update, processor_id, allocation_flag)
    FacilitiesUser.create_facilities_to_user(facility_ids_to_create, processor_id, allocation_flag)
    idle_processor = IdleProcessor.find_by_user_id(processor_id)
    if !idle_processor.blank?
      IdleProcessor.delete(idle_processor.id)
    end
    JobAllocator::allocate_facility_wise([processor_id])
    redirect_to :action => "associate_facilities_to_users", :id => processor_id, :page => params[:page]
  end

  def idle_processors
    relation_include = [{:roles_users => :role}]
    @idle_users = User.where(["users.login_status = ? and
                        users.allocation_status = ? and roles.name = ?", 1, 0, "processor"]).
      includes(relation_include).
      paginate(:per_page => 10, :page => params[:page])
  end

  def associate_facilities_to_users
    @processor = User.find(params[:id])
    condition_string, condition_values = apply_conditions
    @facilities = Facility.select("
        clients.name AS client_name, \
        facilities.id, \
        facilities.name AS facility_name, \
        facilities.sitecode AS site_code, \
        facilities_users.id AS facility_user_id, \
        facilities_users.eobs_processed, \
        facilities_users.eligible_for_auto_allocation, \
        facilities_users.id as facility_user_id
      ").
      joins("INNER JOIN clients ON clients.id = facilities.client_id
        LEFT OUTER JOIN facilities_users ON facilities_users.facility_id = facilities.id AND facilities_users.user_id = #{@processor.id}").
      provides_conditions_with_relation_to_facilities_users(condition_string, condition_values).
      group("facilities.id").paginate(:page => params[:page], :per_page => 30)
  end

  def apply_conditions
    condition_strings = []
    condition_values = []
    if !params[:search_key].blank? && !params[:search_value].blank?
      search_value = params[:search_value].to_s.strip.upcase
      case params[:search_key].to_s
      when 'Facility Name'
        condition_strings << "facilities.name LIKE ?"
        condition_values << "#{search_value}%"
      when 'Client Name'
        condition_strings << "clients.name LIKE ?"
        condition_values << "#{search_value}%"
      when 'Facility Experience'
        compare = params[:compare]
        compare = '=' if compare.blank?
        condition_value = search_value
        condition_value = '0' if condition_value.blank?
        
        if condition_value == '0' && compare == '='
          condition_string = "facilities_users.eobs_processed #{compare} ? OR facilities_users.eobs_processed IS NULL"
        else
          condition_string = "facilities_users.eobs_processed #{compare} ?"
        end

        condition_strings << condition_string
        condition_values << condition_value
      when 'Allocation Type'
        case search_value
        when 'NO'
          condition_string = "facilities_users.eligible_for_auto_allocation = ? OR facilities_users.eligible_for_auto_allocation IS NULL"
          condition_value = 0
        when 'YES'
          condition_string = "facilities_users.eligible_for_auto_allocation = ?"
          condition_value = 1
        else
          condition_string = "facilities_users.eligible_for_auto_allocation = ?"
          condition_value = 2
        end
        condition_strings << condition_string
        condition_values << condition_value
      end
    end

    if !condition_strings.blank? && !condition_values.blank?
      condition_strings = condition_strings.join(" AND ")
      condition_values = condition_values.join(', ')
    end

    return condition_strings, condition_values
  end
  
end

