class ProviderAdjustmentsController < ApplicationController
  
  include InsurancePaymentEobsHelper
  include ProviderHelper

  before_filter :prepare, :only => [:create]

  def list
    @job_id = params[:job_id]
    @prov_adjustment_description = provider_adjustment_descriptions
    @is_partner_bac = $IS_PARTNER_BAC
    @allow_special_characters = @facility.details[:patient_account_number_hyphen_format] if @facility
    render :partial => "list"
  end
  
  def create
    job_id = params[:job_id]
    qualifier = params[:prov_adjustment_description]    
    @prov_adjustment_description_hash = prov_adjustment_details
    description = @prov_adjustment_description_hash.index(qualifier)
    amount = params[:prov_adjustment][:amount]
    account_number = params[:prov_adjustment][:account_number].to_s.strip.upcase
    image_page_no = params[:prov_adjustment][:image_page_number].strip
    if !image_page_no.blank? && !description.blank? && !amount.blank? && !amount.to_f.zero?
      description = description.dup
      description.slice!(0..4)
      provider_adjustment = ProviderAdjustment.new(
        :description => description,
        :qualifier => qualifier,
        :amount => amount,          
        :patient_account_number => account_number,
        :image_page_number => image_page_no, 
        :job_id => job_id)
      provider_adjustment.client_code = provider_adjustment.get_client_code(@facility, @batch, @payer_type)
      provider_adjustment.save

      JobActivityLog.create_activity({:job_id => job_id, :allocated_user_id => current_user.id,
          :activity => 'Provider Adjustment Created', :start_time => Time.now,
          :object_name => 'provider_adjustments', :object_id => provider_adjustment.id,
          :field_name => 'qualifier', :new_value => qualifier })
      flash[:error] = "Provider adjustment created successfully"
    else
      flash[:error] = "Page number, Description and amount(non zero) are mandatory fields"
    end
    redirect_to :action => "list", :job_id => job_id, :allow_special_characters => params[:allow_special_characters],
      :facility_name => params[:facility_name]
  end

  # This is for showing the summary of Provider adjustments.
  # For QA, this summary shows provider_ajudtments of all child_jobs belonging
  # to the same parent as that of the current.For Processor(Proc view and
  # Completed EOB view), it will show only current job's provider adjustment
  # details.
  # Input: Params of Job_id and role_is_qa
  # Output: Provider adjustment record(s).

  def provider_adjustment_summary
    ids_of_all_jobs = []
    job_id = params[:job_id]
    job = Job.find(job_id)
    ids_of_all_jobs += job.get_ids_of_all_child_jobs
    ids_of_all_jobs << job_id
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')})"
    @parent_job_id = job.parent_job_id
    @provider_adjustments = ProviderAdjustment.find(:all,
      :conditions => conditions, :order => "provider_adjustments.image_page_number ASC")
  end
  
  def destroy
    if ProviderAdjustment.find(params[:id]).destroy
      flash[:error] = "Provider adjustment deleted successfully."
    else
      flash[:error] = "Failed deleting provider adjustment."
    end
    redirect_to :action => "provider_adjustment_summary", :job_id => params[:job_id]
  end

  def prepare
    unless params[:job_id].blank?
      @job = Job.includes({:batch => {:facility => :client}}).find(params[:job_id])
      @batch = @job.batch
      @facility = @batch.facility      
      @payer_type = @job.payer_group
      if @payer_type.blank? || @payer_type == '--'
        @check_information = CheckInformation.check_information(params[:job_id])      
        micr = @check_information.micr_line_information
        payer = micr.payer if micr
        payer = @check_information.payer if payer.blank?
        @payer_type = payer.payer_type if payer
      end
    end
  end
  
end

