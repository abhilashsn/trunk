#require 'will_paginate/array'

class Admin::AchExceptionController < ApplicationController

  require_role ["admin", "supervisor", "manager"]
  layout 'standard'

  
  def index
    #find all exceptions
    @cr_transactions = CrTransaction.exceptions
    
    #apply filters
    unless params[:arrival_date_from].blank? && params[:arrival_date_to].blank?
      if params[:arrival_date_from].blank? && !params[:arrival_date_to].blank?
        flash[:notice] = 'Please select "From" Date'
      elsif params[:arrival_date_to].blank? && !params[:arrival_date_from].blank?
        flash[:notice] = 'Please select "To" Date'
      else
        @cr_transactions = @cr_transactions.where("ach_files.file_arrival_date >= '#{params[:arrival_date_from]}' AND ach_files.file_arrival_date <= '#{params[:arrival_date_to]}'")
      end
    end
    @cr_transactions = @cr_transactions.where(" ach_files.file_name = '#{params[:filename].strip}'") unless params[:filename].blank?
    @cr_transactions = @cr_transactions.where("eft_trace_number_ed = '#{params[:trace_number].strip}' OR eft_trace_number_eda = '#{params[:trace_number].strip}'") unless params[:trace_number].blank?
    @cr_transactions = @cr_transactions.where("status = '#{params[:exception]}'") unless params[:exception].blank?
    @cr_transactions = @cr_transactions.where("receivers_name = '#{params[:site_name].strip}'") unless params[:site_name].blank?
    unless params[:site_aba_dda].blank?
      aba_dda_number = params[:site_aba_dda].strip.split("-")
      @cr_transactions = @cr_transactions.joins(:aba_dda_lookup).where("aba_dda_lookups.aba_number = '#{aba_dda_number[0]}' AND aba_dda_lookups.dda_number = '#{aba_dda_number[1]}'")
    end
    @cr_transactions = @cr_transactions.where("payer_name = '#{params[:payer_name].strip}'") unless params[:payer_name].blank?
    @cr_transactions = @cr_transactions.where("company_id = '#{params[:company_id].strip}'") unless params[:company_id].blank?
    
    #order by status and paginate
    @cr_transactions = @cr_transactions.by_status.paginate(:page => params[:page])
  end

  def approval
    @cr_transaction = CrTransaction.find(params[:cr_id])
    aba_dda_lookup = @cr_transaction.aba_dda_lookup
    
    if params[:site_search_button]
      if !params[:site_search].blank?
        @facilities = Facility.where("name LIKE ?", "%#{params[:site_search]}%").paginate(:per_page => 6, :page => params[:page])
      else
        @facilities = nil
      end
    elsif params[:approvesite_button]
      facility = Facility.find_by_name(params[:site_search])
      if facility
       aba_dda_lookup.update_attributes(facility_id: facility.id)
       CrTransaction.update_site_status(aba_dda_lookup, "remove")
       flash[:notice] = "The site you have entered has been approved"
      else
       flash[:notice] = "The site you have entered does not exist in the system. Please enter a valid site and click Approve"
      end
    elsif params[:rejectsite_button]
      facility = Facility.find_or_initialize_by_name("BLACKLISTED")
      facility.new_record? ? facility.save(validate: false) : nil
      aba_dda_lookup.update_attributes(facility_id: facility.id)
      
      aba_dda_lookup.cr_transactions.each do |crt|
        crt.destroy
      end
      
      flash[:notice] = "The site has been rejected"
    elsif params[:payer_search_button]
      if !params[:payer_search].blank?
        @payers = Payer.where("payer LIKE ?", "%#{params[:payer_search]}%").paginate(:per_page => 6, :page => params[:page])
      else
        @payers = nil
      end
    elsif params[:approvecompanyid_button]
      payer = Payer.find_by_payer(params[:payer_search])
      
      if payer
        if !payer.company_id
          payer.update_attributes(company_id: @cr_transaction.company_id)
          CrTransaction.update_payer_status(payer.company_id)
          flash[:notice] = "The Company ID you entered has been approved"
        else
          flash[:notice] = "The selected payer is already mapped to a Company ID: #{payer.company_id}! Please select another payer or create a new payer"
        end
      else
        flash[:notice] = "The payer you have entered does not exist in the system. Please enter a valid payer and click Approve, else create a New Payer"
      end
    elsif params[:createpayer_button]
      redirect_to controller: 'payer', action: 'new', :payer => @cr_transaction.payer_name, :company_id => @cr_transaction.company_id
    end
    
    #respond_to do |format|
    #  format.html
    #  format.js
    #end
  
  end

end
