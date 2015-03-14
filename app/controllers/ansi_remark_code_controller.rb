class AnsiRemarkCodeController < ApplicationController

  layout 'standard'
  require_role ["admin","supervisor"]

  def index
    @ansi_remark_codes = AnsiRemarkCode.scoped.paginate(:page => params[:page])
  end

  def new
  end

  def create
    unless params[:ansi_remark_code][:adjustment_code].blank?
      params[:ansi_remark_code][:adjustment_code] = (params[:ansi_remark_code][:adjustment_code]).strip
    end
    if(params[:ansi_remark_code][:adjustment_code].blank? || params[:ansi_remark_code][:adjustment_code_description].blank?)
      flash[:notice] = "Please Enter the ANSI Remark Code and Description"
      redirect_to :action => :new
    elsif AnsiRemarkCode.exists?(:adjustment_code => params[:ansi_remark_code][:adjustment_code])
      flash[:notice] = "ANSI Remark Code #{params[:ansi_remark_code][:adjustment_code]} already exists"
      redirect_to :action => :new
    else
      AnsiRemarkCode.create(params[:ansi_remark_code])
      flash[:notice] = "ANSI Remark Code #{params[:ansi_remark_code][:adjustment_code]} is created"
      redirect_to :action => :index
    end
  end

  def edit
    @ansi_remark_code = AnsiRemarkCode.find(params[:id])
  end

  def update
    ansi_remark_code = AnsiRemarkCode.find(params[:id])
    unless params[:ansi_remark_code][:adjustment_code].blank?
      params[:ansi_remark_code][:adjustment_code] = (params[:ansi_remark_code][:adjustment_code]).strip
    end
    if(params[:ansi_remark_code][:adjustment_code].blank? || params[:ansi_remark_code][:adjustment_code_description].blank?)
      flash[:notice] = "Please Enter the ANSI Remark Code and Description"
      redirect_to :action => :edit, :id => ansi_remark_code.id
    else      
      ansi_remark_code_exists = AnsiRemarkCode.find(:first, :conditions => ["adjustment_code = ? and id != ?", params[:ansi_remark_code][:adjustment_code], ansi_remark_code.id])
      if !ansi_remark_code_exists.blank?
        flash[:notice] = "ANSI Remark Code #{params[:ansi_remark_code][:adjustment_code]} already exists"
        redirect_to :action => :edit, :id => ansi_remark_code.id
      else        
        ansi_remark_code.update_attributes(params[:ansi_remark_code])
        flash[:notice] = "ANSI Remark Code #{params[:ansi_remark_code][:adjustment_code]} successfully updated"
        redirect_to :action => :index
      end
    end
  end

  def destroy
    ansi_remark_code = AnsiRemarkCode.find(params[:id])
    if ansi_remark_code.reason_codes.blank?
      if ansi_remark_code.destroy
        flash[:notice] = "Ansi Remark Code : #{ansi_remark_code.adjustment_code} has been deleted successfully"
      end
    else
      flash[:notice] = "Ansi Remark Code : #{ansi_remark_code.adjustment_code} has a reason code associated to it, so cannot delete it"
    end
    redirect_to :action => :index
  end

end
