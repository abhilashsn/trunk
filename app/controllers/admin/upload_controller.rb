#################################################################
# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
#Product:Revcapture
#Version:
#Author :
#Modified by Anoop
#Modified date 24/09/2008
#####################################################################
class Admin::UploadController < ApplicationController
  layout 'standard'
  require_role ["admin","manager","supervisor"]

  def upload
    @type = params[:type]
    @batch = params[:batch]
  end
  #Using a gem for upload string with commas
  #Modified by Dhanya
  require 'csv'  #Using CSV for parsing
  def create
    logger.debug "In UploadController#create"
    @batch = params[:batch]
    @type = params[:type]
    r  = 0
    l  = 0
    if @type=='payer'
      j = 0
      @parsed_file=CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|
        new_payer = Payer.new
        new_payer.gateway = row[0] unless row[0].blank?
        new_payer.payid = row[2] unless row[2].blank?
        new_payer.payer = row[1] unless row[1].blank?
        # TODO: Find out why below isn't row[3]
        if row[3] != "-"
          new_payer.gr_name = row[3]
        end
        new_payer.pay_address_one = row[4] unless row[4].blank?
        new_payer.payer_city = row[5] unless row[5].blank?
        new_payer.payer_state = row[6] unless row[6].blank?
        new_payer.payer_zip = row[7] unless row[7].blank?
        new_payer.plan_type ="PPO including BCBS "
        id = row[2]
        person = Payer.find_by_payid(id)
        # for skipping first line from csv
        if (j>=1)
          if new_payer.save
            new_payer.payer_type = new_payer.id
            new_payer.save
            r  = r + 1
            n = n + 1
          end
        end
        GC.start if n%50 == 0
        #flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
        # end 
        j = j + 1
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Data Base"
      elsif r>0 and l>0
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif r==0 and l>0
        flash[:notice]  = "Updated"
      end
      redirect_to :controller => '/admin/upload', :action => 'upload' , :batch => @batch, :type => @type
    elsif @type == 'micr_payer'
      j = 0
      @parsed_file= CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|
        #Extracting micr_line data ie:aba_routing_number and payer_account_number
        aba_routing_number = row[1] unless row[1].blank?
        payer_account_number = row[2] unless row[2].blank?
        payid = row[4] unless row[4].blank?
        payer = Payer.find_by_payid(payid) unless payid.blank?
        # for skipping first line from csv
        if (j>=1)
          #Importing micr_line data ie:aba_routing_number and payer_account_number
          #from the micr master csv file. For this comparing payid in the csv file
          #and the payid of the imported payers in the payers table and inserts a row in
          #micr_line_informations table with aba_routing_number,payer_account_number, payer_id
          #obtained by the match from payers table and status set as "Approved".
          unless aba_routing_number.blank? and payer_account_number.blank?
            MicrLineInformation.create(:aba_routing_number => aba_routing_number , :payer_account_number => payer_account_number, :payer_id => payer.id, :status => "Approved") if payer
          end
          r  = r + 1
          n = n + 1
        end
        GC.start if n%50 == 0
        j = j + 1
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Data Base"
      elsif r>0 and l>0
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif r==0 and l>0
        flash[:notice]  = "Updated"
      end
      redirect_to :controller => '/admin/upload', :action => 'upload' , :batch => @batch, :type => @type
    elsif  @type=='user'
      j = 0
      @parsed_file=CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|
        new_user = User.new
        new_user.name = row[0]
        new_user.password = row[2]
        new_user.userid = row[1]
        # TODO: Find out why below isn't row[3]
        #  new_user.gr_name = ""
        new_user.role = row[3]
        id = row[1]
        person = User.find_by_userid(id)
        if person.blank?
          # for skipping first line from csv
          if (j>=1)
            @shift =Shift.find_by_name(row[4])
            new_user.shift_id = @shift.id
            if new_user.save
              r  = r + 1
              n = n + 1
            end
          end
        end
        GC.start if n%50 == 0
        j=j+1
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Data Base"
      end  
      redirect_to :controller => '/admin/upload', :action => 'upload' , :batch => @batch, :type => @type
    else
      @parsed_file=CSV.read(params[:upload][:file].path,"r:Windows-1252")
      i=0
      n = 0
      @parsed_file.each  do |row|
        @job = Job.new
        batch_id = row[0]
        if !batch_id.blank? and i>=1
          @batch =  Batch.find_by_batchid(batch_id)
          @job.batch_id = @batch.id
          @job.check_number = row[1]
          @job.tiff_number = row[2]
          @job.estimated_eob = row[3]
          @job.pages_from = row[4]
          @job.pages_to = row[5]
          @payer = Payer.find_by_payer("No Payer")
          @job.payer_id = @payer.id
          @job.save
          if @job.save
            @image_for_job = ImagesForJob.find_by_batch_id(@batch.id)
            @client_image = ClientImagesToJob.new(:job_id=>@job.id,:images_for_job_id => @image_for_job.id)
            @client_image.save
            @batch.update_attribute("eob",@job.pages_to)
            r  = r + 1
            n = n + 1
          end
        end
        GC.start if n%50 == 0
        i=i+1
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Data Base"
      end
      redirect_to :controller => '/admin/batch', :action => 'add_job', :id => params[:batch]
    end
  end
end

