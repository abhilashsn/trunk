# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  protect_from_forgery :only => [:create, :update, :destroy]
  skip_before_filter :authenticate_user!, :only => [:version, :disclaimer, :destroy]

  layout 'standard'

  def version
    current_user
    @version_settings = YAML.load_file("#{Rails.root}/config/version.yml")
    @config   = []
    @config << ["RevRemit version",@version_settings['application']['version']]
    @config << ["Ruby version",RUBY_VERSION]
    @config << ["Rails version", Rails.version]
    @config << ["Application root",Rails.root]
    @config << ["Environment",Rails.env]
    @config << ["Database",Rails.configuration.database_configuration[Rails.env]["database"]]
    @config << ["Database Server",Rails.configuration.database_configuration[Rails.env]["host"]]
    @config << ["Migration version",ActiveRecord::Migrator.current_version]
    @config << ["Release date",@version_settings['application']['release_date']]
    svn_path = `svn info|grep URL:`
    svn_path = svn_path.gsub('URL:', '')
    svn_path = ' -   ' if svn_path.empty?
    @config << ["SVN URL",svn_path]
    svn_ver = `svn info|grep Revision:`
    svn_ver = svn_ver.gsub('Revision:', '')
    svn_ver = ' -   ' if svn_ver.empty?
    @config << ["SVN Revision",svn_ver]
  end

  # disclaimer view page is used without authentication
  def disclaimer
  end

  def new
  end

  def create
    if current_user
      user = current_user
      session[:user_logged_in] = true
      session[:user_id] = user.id
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      user.login_status = ONLINE
      if(user.has_role?(:processor))
        if user.auto_allocation_enabled == false
          user.auto_allocation_enabled = true
        end
      end
      user.save
      flash[:error] = "Logged in successfully."
      unless (user.password_changed_at.blank?)
        expiry_time = User.expire_password_after
        if ((Date.parse("#{Time.now}")   - Date.parse("#{user.password_changed_at}")) >= 85)
          flash[:error] += "Your Password will expire soon Please change and continue!"
        end
      end
      UserActivityLog.create_activity_log(current_user, 'Logged in',nil,nil,user.current_sign_in_ip)
      if user.reset_password
        redirect_to :controller => 'admin/user', :action => "change_password"
      else
        redirect_back_or_default(url_for(:action => 'index', :controller => 'dashboard'))
      end

    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      redirect_to :controller => 'devise/sessions', :action => 'new'
    end
  end

  def destroy
    if !current_user.blank?
      user = current_user
    elsif !params[:user_id].blank?
      user = User.find(params[:user_id])
    end
    session[:user_id] = nil
    unless user.blank?
      session[:user_logged_in] = false
      user.login_status = OFFLINE
      user.save
      UserActivityLog.create_activity_log(user, 'Logged out',nil,nil,user.current_sign_in_ip)
      if user.has_role?(:processor)
        IdleProcessor.delete_all("user_id = #{user.id}")
      end
    end
    flash[:notice] = "You have been logged out."
    redirect_to :controller => 'devise/sessions', :action => 'destroy'
  end

  def keep_alive
    session[:user_logged_in] = true
    render :text => "OK", :layout => false
  end

  def get_user_logged_in
    text = ''
    if session[:user_logged_in]
      text = "OK"
    end
    render :text => text, :layout => false
  end


  protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = " Invalid user/password combination."
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end

