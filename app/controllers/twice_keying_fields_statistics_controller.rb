class TwiceKeyingFieldsStatisticsController < ApplicationController
  layout 'standard'
  
  def list
    @field_options = ['--', 'Date', 'Client', 'Facility', 'Payer ID', 'Payer Name',
      'Field Name', 'Processor Name', 'Processor Emp ID', 'Batch Date',
      'Batch ID', 'Status']
    condition_string, condition_values, flash_notice = TwiceKeyingFieldsStatistics.get_conditions(params)
    if condition_string.present? && condition_values.present?
      @records = TwiceKeyingFieldsStatistics.list_data(condition_string, condition_values).
        paginate(:page => params[:page], :per_page => 30)
      flash[:notice] = flash_notice if flash_notice.present?
    end
  end

  def export_list
    condition_string, condition_values, flash_notice = TwiceKeyingFieldsStatistics.get_conditions(params)
    if condition_string.present? && condition_values.present?
      records = TwiceKeyingFieldsStatistics.list_data(condition_string, condition_values).all
      csv = CSV.generate do |row|
        row << ['Date', 'Client', 'Facility', 'Payer ID', 'Payer Name', 'Batch Date',
          'Batch ID', 'Check Number', 'Patient Account Number', 'Field Name',
          'Processor Emp ID', 'Processor Name', 'Status']

        if records.present?
          records.each do |record|
            date_of_keying = (format_datetime(convert_to_ist_time(record.date_of_keying),'%m/%d/%y') || '-')
            batch_date = format_datetime(record.batch_date,'%m/%d/%y') || '-'
            first_attempt_status = record.normalize_first_attempt_status

            row << [date_of_keying, record.client_name.to_s.upcase, record.facility_name.to_s.upcase,
              record.payid.to_s.upcase, record.payer_name.to_s.upcase, batch_date, record.batchid.to_s.upcase,
              record.check_number.to_s.upcase, "'" + record.patient_account_number.to_s.upcase + "'",
              record.normalize_field_name, record.employee_id.to_s.upcase,
              record.processor_name.to_s.upcase, first_attempt_status]
          end
        end
      end
    end
    if flash_notice.present?
      flash[:notice] = flash_notice
      logger.error "#{flash_notice}"
    end

    today = Time.now.to_s.split(' ').first
    send_data csv, :type=> 'text/csv', :filename => "Double_Keying_Statistics_#{today}.csv"
  end
  
end
