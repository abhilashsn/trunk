# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::StatusController < ApplicationController
   require_role "admin"
  layout 'standard'
  def index
    list
    render :action => 'list'
  end

  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def list
    @status_pages, @statuses = paginate :statuses
  end

  def delete_status
    statuss = params[:status_to_delete]
    statuss.delete_if do |key, value|
      value == "0"
    end
    
    # REFACTORED
    # statuss.keys.each do |id|
    #  Status.find(id).destroy
    # end
    
    Status.destroy statuss.keys

  if statuss.size != 0
    flash[:notice] = "Deleted #{statuss.keys.size} Status(es)"
  else
    flash[:notice]="Please select atleast one status to delete ."
  end

    redirect_to :action => 'list'
  end


  def show
    @status = Status.find(params[:id])
  end

  def new
    @status = Status.new
  end

  def create
    @status = Status.new(params[:status])
    if @status.save
      flash[:notice] = 'Status was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @status = Status.find(params[:id])
  end

  def update
    @status = Status.find(params[:id])
    if @status.update_attributes(params[:status])
      flash[:notice] = 'Status was successfully updated.'
      redirect_to :action => 'show', :id => @status
    else
      render :action => 'edit'
    end
  end

  def destroy
    Status.destroy params[:id]
    redirect_to :action => 'list'
  end

  def validate
    unless @user and @user.role == 'Supervisor'
      flash[:notice] = 'You don\'t have necessary permission.'
      redirect_to :controller => '/dashboard', :action => 'index'
    end
  end
end
