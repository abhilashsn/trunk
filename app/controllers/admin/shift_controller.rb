# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::ShiftController < ApplicationController
    require_role "admin"
  layout 'standard'
  
  def index
    redirect_to :action => 'list'
  end
  
  def list
    @shifts = Shift.find(:all)
  end
  
  def edit
    @shift = Shift.find(params[:id])
  end
  
  def new
    @shift = Shift.new
  end
  
  def create
    @shift = Shift.new(params[:shift])
    @shift.start_time = Time.parse("#{params[:set_time][:hour]}" + ":" + "#{params[:set_time][:minute]}")
    @shift.name = params[:shift][:name].capitalize
    if @shift.save
      flash[:notice] = "#{@shift.name} Shift has been created successfully."
      redirect_to :action => :list
    else
      render :action => 'edit'
    end
    
  end
  
  def update
    @shift = Shift.find(params[:id])
    @shift.start_time = Time.parse("#{params[:set_time][:hour]}" + ":" + "#{params[:set_time][:minute]}")
    @shift.duration = params[:shift][:duration]
    @shift.name = params[:shift][:name].capitalize
    if @shift.save
      flash[:notice] = "Shift details updated."
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  def delete
    if params[:id].to_i >= 1 and params[:id].to_i <= 4
      flash[:notice] = "Default shifts can not be deleted!"
      redirect_to :action => :list
    else
      @shift = Shift.find(params[:id])
      @shift_users = @shift.users
      @shift_users.each {|u| u.shift = Shift.find(1); u.save}
      if @shift.destroy
        flash[:notice] = "Shift has been deleted. All users shifted to General Shift."
        redirect_to :action => :list
      end
    end
  end
end
