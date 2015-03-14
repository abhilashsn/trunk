namespace :input do

  desc "The task to create the plans for the FM dashboard usage.."
  task :create_plans, [:start_date, :number_of_days] => [:environment]  do |t, args|
    unless args.start_date && args.number_of_days
      raise "The Start Date and Number Of Days are mandatory as parameters....An example rake call is given below..\n 'rake input:create_plans start_date='20-10-2010' number_of_days=10'"
    else
      begin
        date_in_the_argument = args.start_date.to_date
        max_date = InboundFileInformation.find_by_sql("select max(expected_arrival_date) as current_max_date from inbound_file_informations").first.current_max_date
        current_max_date = max_date.to_date if max_date
        day_hash = {"MON" => 1, "TUE" => 2, "WED" => 3, "THU" => 4, "FRI" => 5, "SAT" => 6, "SUN" => 7}
        if current_max_date
          if date_in_the_argument > current_max_date
            date = date_in_the_argument
          else
            date = current_max_date
            date += 1
          end
        else
          date = date_in_the_argument
        end
        total_ifi_created = 0
        for date_incrementer in 1..args.number_of_days.to_i
          day = date.strftime("%a").upcase
          fcr = FacilityCutRelationship.where("day='#{day}'").includes(:facility)
          unless fcr.empty?
            inbound_file_informations = []
            fcr.each do |facility_cut_data|
              expected_day_number = day_hash[facility_cut_data.expected_day_of_arrival]
              absolute_day_difference = (date.cwday - expected_day_number).abs
              batchdate = date
              expected_arrival_date = absolute_day_difference == 0 ? date : find_the_original_date(facility_cut_data,date)
              expected_arrival_date = formatted_expected_arrival_date(expected_arrival_date,facility_cut_data)
              facility = facility_cut_data.facility
              lockbox_name = FacilityLockboxMapping.find_by_lockbox_number(facility_cut_data.lockbox_number).lockbox_name rescue nil
              expected_start_time = expected_arrival_date - facility.file_arrival_threshold.hour
              expected_end_time = expected_arrival_date + facility.file_arrival_threshold.hour
              inbound_file_informations << facility.inbound_file_informations.new(:cut => facility_cut_data.cut, :batchdate => batchdate, :expected_arrival_date => expected_arrival_date, :expected_start_time => expected_start_time, :expected_end_time => expected_end_time, :lockbox_name => lockbox_name, :lockbox_number => facility_cut_data.lockbox_number, :status => "PENDING", :file_type=>'LOCKBOX')
            end
            total_ifi_created += inbound_file_informations.length
            InboundFileInformation.import inbound_file_informations
          end
          date += 1
        end
        puts "The total inbound_file_information rows created are #{total_ifi_created}"
      rescue Exception => e
        puts "The plan for the given days can't be fully created as there are some data related issues..."
        puts "The system error which occured is '#{e.message}'"
        Rails.logger.debug "The error occured while creating the plan today, #{Date.today} was.. \n #{e}"
      end
    end
  end

  def formatted_expected_arrival_date(expected_arrival_date,facility_cut_data)
    real_date_time = expected_arrival_date.strftime("%Y-%m-%d") + " " + facility_cut_data.time.localtime.strftime("%H:%M:%S") rescue nil
    time_in_utc = Time.parse(real_date_time).utc rescue ""
    return time_in_utc
  end

  def find_the_original_date(fcr,date)
    day_diff_hash = {"SAT,MON" => 2, "SUN,MON" => 1,"SAT,TUE" => 3, "SUN,TUE" => 2}
    key = fcr.expected_day_of_arrival + ",#{fcr.day}"
    day_diff = day_diff_hash[key]
    return (date - day_diff) rescue nil
  end
  
end
