# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::QaReportController < ApplicationController
    require_role "admin"
  layout 'standard'

  def qa_daily_report
    search_field_from_date = params[:to_find1] #Text field for from date
    @search_field2 = params[:to_find2] #text field for 2nd criteria like A/c No., Processor
    search_field_to_date = params[:to_find3] #Text field for to date
    @criteria1 = params[:criteria1] #
    @criteria2 = params[:criteria2] #Combo box for selecting criteria (A/c No., Processor)
    @compare2 = params[:compare2] #Combobox for <,=,>
    search_field_from_date.strip! unless search_field_from_date.nil?
    search_field_to_date.strip! unless search_field_to_date.nil?
    @search_field2.strip! unless @search_field2.nil?

    if not search_field_from_date.blank?
      if search_field_to_date.blank?
        begin
          Date.strptime(search_field_from_date,"%m/%d/%y")
          @from_date = convert_to_est_time((search_field_from_date.to_time) + 7.hours)
          @to_date = convert_to_est_time(((search_field_from_date.to_time).tomorrow) + 7.hours)
        rescue ArgumentError
          flash[:notice] = "Invalid date format (mm/dd/yy)"
          @from_date = convert_to_est_time(((convert_to_ist_time(Time.now)).at_beginning_of_day) + 7.hours)
          @to_date = convert_to_est_time((((convert_to_ist_time(Time.now)).tomorrow).at_beginning_of_day) + 7.hours)
        end
      else
        begin
          Date.strptime(search_field_from_date,"%m/%d/%y")
          Date.strptime(search_field_to_date,"%m/%d/%y")
          @from_date = convert_to_est_time((search_field_from_date.to_time) + 7.hours)
          @to_date = convert_to_est_time(((search_field_to_date.to_time).tomorrow) + 7.hours)
        rescue ArgumentError
          flash[:notice] = "Invalid date format (mm/dd/yy)"
          @from_date = convert_to_est_time(((convert_to_ist_time(Time.now)).at_beginning_of_day) + 7.hours)
          @to_date = convert_to_est_time((((convert_to_ist_time(Time.now)).tomorrow).at_beginning_of_day) + 7.hours)
        end
      end
    else
      if not search_field_to_date.blank?
        begin
          Date.strptime(search_field_to_date,"%m/%d/%y")
          @from_date = convert_to_est_time((search_field_to_date.to_time) + 7.hours)
          @to_date = convert_to_est_time(((search_field_to_date.to_time).tomorrow) + 7.hours)
        rescue ArgumentError
          flash[:notice] = "Invalid date format (mm/dd/yy)"
          @from_date = convert_to_est_time(((convert_to_ist_time(Time.now)).at_beginning_of_day) + 7.hours)
          @to_date = convert_to_est_time((((convert_to_ist_time(Time.now)).tomorrow).at_beginning_of_day) + 7.hours)
        end
      else
         @from_date = convert_to_est_time(((convert_to_ist_time(Time.now)).at_beginning_of_day) + 7.hours)
			   @to_date = convert_to_est_time((((convert_to_ist_time(Time.now)).tomorrow).at_beginning_of_day) + 7.hours)
			end
    end

    if not @search_field2.blank?
      filtered_report = filter_for_daily_report(@criteria2, @compare2, @search_field2, @from_date, @to_date)
      if filtered_report.size == 0
        flash[:notice] = " No record found for <i>#{@criteria2} #{@compare2} \"#{@search_field2}\"</i>"
        redirect_to :action => 'qa_daily_report'
      else
        @reports = filtered_report.paginate(:per_page => 100 ,:page => params[:page])
      end
    else
      @reports = EobReport.find(:all, :conditions => ["verify_time >= ? and
              verify_time <= ?",@from_date.to_time, @to_date.to_time]).
              paginate(:per_page => 100 ,:page => params[:page])
    end
    
  end

  def filter_for_daily_report(field, comp, search, from_date, to_date)
    case field
      when 'Account Number'
        reports = EobReport.find(:all, :conditions => ["account_number like '%#{search}%' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Processor'
        reports = EobReport.find(:all, :conditions => ["processor = '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Accuracy %'
        reports = EobReport.find(:all, :conditions => ["Accuracy #{comp} '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'QA'
        reports = EobReport.find(:all, :conditions => ["qa = '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Batch ID'
        reports = EobReport.find(:all, :conditions => ["batch_id #{comp} '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Batch Date'
        begin
          	date = Date.strptime(search,"%m/%d/%y")
        rescue ArgumentError
            flash[:notice] = "Invalid date format"
        end
        reports = EobReport.find(:all, :conditions => ["batch_date #{comp} '#{date}' and verify_time >= ? and verify_time<= ?",@from_date.to_time, @to_date.to_time])
      when 'Total Fields'
        reports = EobReport.find(:all, :conditions => ["total_fields #{comp} '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Incorrect Fields'
        reports = EobReport.find(:all, :conditions => ["incorrect_fields #{comp} '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Error Severity'
        reports = EobReport.find(:all, :conditions => ["error_severity #{comp} '#{search}' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
      when 'Error Code'
        reports = EobReport.find(:all, :conditions => ["error_code like '%#{search}%' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
        reports = reports.select do |report|
            report.eob_error.code == search
        end
      when 'Status'
        reports = EobReport.find(:all, :conditions => ["status like '%#{search}%' and verify_time >= ? and verify_time <= ?",@from_date.to_time, @to_date.to_time])
    end
  end

  def qa_monthly_report
    @search_field = params[:to_find]
    @compare = params[:compare]
    @criteria = params[:criteria]
    @search_field.strip! unless @search_field.nil?
    @from_date = Time.now.at_beginning_of_month
    @to_date = Time.now
    if not @search_field.blank?
      if @criteria == 'Date'
        begin
          	date = Date.strptime(@search_field,"%m/%d/%y")
          	@from_date = convert_to_est_time((@search_field.to_time).at_beginning_of_month)
            @to_date = convert_to_est_time(((@search_field.to_time).at_beginning_of_month).months_since(1))
        rescue ArgumentError
            flash[:notice] = "Invalid date format"
        end
      end
      filtered_errors = filtering_error(@criteria, @compare, @search_field, @from_date, @to_date)
      if filtered_errors.size == 0
        flash[:notice] = " No record found for <i>#{@criteria} #{@compare} \"#{@search_field}\"</i>"
        redirect_to :action => 'qa_monthly_report'
      else
        @errors = filtered_errors.paginate(:per_page => 30 ,:page => params[:page])
      end
    else
      @errors = EobReport.find(:all, :conditions => ["verify_time >= ? and verify_time < ?",@from_date, @to_date],
                          :group => "qa, processor",
                          :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa",
                          :order => "processor").paginate(:per_page => 30 ,:page => params[:page])
    end
    
  end

  def filtering_error(field, comp, search, from_date, to_date)
    case field
      when 'Processor'
        errors = EobReport.find(:all, :conditions => ["processor = '#{search}' and verify_time >= ? and verify_time < ?",from_date.to_time, to_date.to_time],
                            :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa",
                            :group => "qa, processor")
      when 'Date'
        errors = EobReport.find(:all, :conditions => ["verify_time >= ? and verify_time < ?",from_date.to_time, to_date.to_time],
                            :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa",
                            :group => "qa, processor")
      when 'Error %'
        errors = EobReport.find(:all, :conditions => ["verify_time >= ? and verify_time < ?",from_date.to_time, to_date.to_time],
                            :group => "qa, processor",
                            :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa")
        errors = errors.select do |error|
            qa = User.find_by_userid(error.qa)
            processor = User.find_by_userid(error.processor)
            currect_eobs = qa.eobs_qaed(processor)
            incorrect_eobs = qa.rejected_eobs_qaed(processor)
            case comp
              when '='
                (incorrect_eobs.to_f / currect_eobs.to_f) * 100 == search.to_f
              when '>'
                (incorrect_eobs.to_f / currect_eobs.to_f) * 100  > search.to_f
              when '<'
                (incorrect_eobs.to_f / currect_eobs.to_f) * 100  < search.to_f
            end
        end
      when 'Total EOBs QA Checked'
        errors = EobReport.find(:all, :conditions => ["verify_time >= ? and verify_time < ?",from_date.to_time, to_date.to_time],
                            :group => "qa, processor",
                            :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa")
        errors = errors.select do |error|
            qa = User.find_by_userid(error.qa)
            processor = User.find_by_userid(error.processor)
            currect_eobs = qa.eobs_qaed(processor)
            case comp
              when '='
                 currect_eobs.to_f == search.to_f
              when '>'
                currect_eobs.to_f  > search.to_f
              when '<'
                currect_eobs.to_f  < search.to_f
            end
        end
      when 'Total EOBS QA Rejected'
        errors = EobReport.find(:all, :conditions => ["verify_time >= ? and verify_time < ?",from_date.to_time, to_date.to_time],
                            :group => "qa, processor",
                            :select => "id, sum(incorrect_fields) incorrect_fields, sum(total_fields) total_fields, verify_time, processor, qa")
        errors = errors.select do |error|
            qa = User.find_by_userid(error.qa)
            processor = User.find_by_userid(error.processor)
            incorrect_eobs = qa.rejected_eobs_qaed(processor)
            case comp
              when '='
                 incorrect_eobs.to_f == search.to_f
              when '>'
                incorrect_eobs.to_f  > search.to_f
              when '<'
                incorrect_eobs.to_f  < search.to_f
            end
        end
    end
    return errors
  end

end
