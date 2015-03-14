# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::SiteSettingsController < ApplicationController
    require_role "admin"
  layout 'standard'
  
  def index
    redirect_to :action => 'edit_settings'
  end

  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def list
    @site_setting_pages, @site_settings = paginate :site_settings, :per_page => 10
  end

  def show
    @site_setting = SiteSetting.find(params[:id])
  end

  def new
    @site_setting = SiteSetting.new
  end

  def create
    @site_setting = SiteSetting.new(params[:site_setting])
    if @site_setting.save
      flash[:notice] = 'SiteSetting was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @site_setting = SiteSetting.find(params[:id])
  end

  def update
    @site_setting = SiteSetting.find(params[:id])
    if @site_setting.update_attributes(params[:site_setting])
      flash[:notice] = 'SiteSetting was successfully updated.'
      redirect_to :action => 'show', :id => @site_setting
    else
      render :action => 'edit'
    end
  end
  
  def edit_settings
    @site_setting = SiteSetting.find(1)
  end
  
  def update_settings
    @site_setting = SiteSetting.find(params[:id])
    if @site_setting.update_attributes(params[:site_setting])
      flash[:notice] = "Settings have been updated."
      redirect_to :action => :edit_settings
    else
      render :action => 'edit_settings'
    end
  end
  
  def destroy
    SiteSetting.destroy params[:id]
    redirect_to :action => 'list'
  end
end
