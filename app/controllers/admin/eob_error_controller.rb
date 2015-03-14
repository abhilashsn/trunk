# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::EobErrorController < ApplicationController
  require_role ["admin","supervisor"]
  layout 'standard'

  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def index
    @eob_errors = EobError.paginate(:page => params[:page], :per_page => 30)    
  end

  def show
    @eob_error = EobError.find(params[:id])
  end

  def new
    @eob_error = EobError.new
  end

  def create
    @eob_error = EobError.new(params[:eob_error])
    if @eob_error.save
      flash[:notice] = 'EobError was successfully created.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @eob_error = EobError.find(params[:id])
  end

  def update
    @eob_error = EobError.find(params[:id])
    if @eob_error.update_attributes(params[:eob_error])
      flash[:notice] = 'EobError was successfully updated.'
      redirect_to :action => 'index', :id => @eob_error
    else
      render :action => 'edit'
    end
  end

  def error_delete
    EobError.destroy params[:id]
    redirect_to :action => 'index'
  end
end
