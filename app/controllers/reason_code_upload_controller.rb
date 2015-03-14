require 'csv'
class ReasonCodeUploadController < ApplicationController
  layout 'standard'
  require_role "admin"

  def upload
    @type = params[:type]
    @payer_id = params[:id]
  end
   
  def create
    logger.debug "In UploadController#create"
    @batch = params[:batch]
    @type = params[:type]
    @payer_id = params[:id]
    r  = 0
    l  = 0
    if @type == 'hipaa'
      j = 0
      @parsed_file = CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|

        c = HipaaCode.new
        c.hipaa_adjustment_code = row[0]
        c.hipaa_code_description = row[1]
        # for skipping first line from csv
        if (j>=1)
          if   c.save
            r  = r + 1
            n = n + 1
            c.add_to_hipaa_codes_global_variable
          end
        end
         
        GC.start if n%50 == 0
        j = j + 1
         
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Database"
      elsif r>0 and l>0
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif r==0 and l>0
        flash[:notice]  = "Updated"
      end

    elsif @type == 'ansi_remark'
      j = 0
      @parsed_file = CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|

        ansi_remark = AnsiRemarkCode.new
        ansi_remark.adjustment_code = row[0]
        ansi_remark.adjustment_code_description = row[1]
        id = row[1]

        # for skipping first line from csv
        if(j >= 1)
          if ansi_remark.save
            r = r + 1
            n = n + 1
          end
        end

        j = j + 1

      end
      if(r > 0 && l == 0)
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Database"
      elsif(r > 0 && l > 0)
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif(r == 0 && l > 0)
        flash[:notice]  = "Updated"
      end

    elsif(@type == 'client' && $IS_PARTNER_BAC)
      j = 0
      @parsed_file = CSV.read(params[:upload][:file].path,"r:Windows-1252")
      n = 0
      @parsed_file.each  do |row|
         
        c = ClientCode.new
        c.group_code = row[0]
        c.adjustment_code = row[1]
        c.adjustment_code_description = row[2]
         
        # for skipping first line from csv
        if (j>=1)
          if   c.save
            r  = r + 1
            n = n + 1
          end
        end
         
        GC.start if n%50 == 0
        j = j + 1
         
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Database"
      elsif r>0 and l>0
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif r==0 and l>0
        flash[:notice]  = "Updated"
      end
    elsif(@type=='reasoncode')
      j = 0
      @parsed_file=CSV.parse(params[:upload][:file].path)
      n = 0
      @parsed_file.each  do |row|
        c = ReasonCode.new
        c.reason_code = row[0]
        c.reason_code_description = row[1]
        if (j>=1)
          client_code = ClientCode.find_by_adjustment_code(row[2]) if $IS_PARTNER_BAC
          hipaa_code = HipaaCode.find_by_hipaa_adjustment_code(row[3])
          payer = Payer.find(@payer_id)
        end
        # TODO: Find out why below isn't row[3]
         
        id = row[0]
        person = ReasonCode.find_by_reason_code(id)
         
        # for skipping first line from csv
        if (j>=1)
          if   c.save
            r  = r + 1
            n = n + 1
          end
        end
         
        GC.start if n%50 == 0
        j = j + 1
         
      end
      if r>0 and l==0
        flash[:notice]  = "CSV Import Successful,  #{n} New Records Added to Database"
      elsif r>0 and l>0
        flash[:notice]  = " #{n} New Records Added to Data Base and Remaining are Updated"
      elsif r==0 and l>0
        flash[:notice]  = "Updated"
      end
       
    end
    if (params[:type]=="hipaa")
      redirect_to :controller => '/hipaa_codes', :action => 'index'
    elsif(params[:type]=="client")
      redirect_to :controller => '/client_codes', :action => 'index'
    elsif(params[:type]=="ansi_remark")
      redirect_to :controller => '/ansi_remark_code', :action => 'index'
    elsif(params[:type]=="reasoncode")
      redirect_to :controller => '/reason_codes', :action => 'index',:id => @payer_id
    end
     
     
  end
end
