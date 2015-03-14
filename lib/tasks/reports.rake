namespace :reports do
  

  desc "To populate the data for throughput report."
  # This inserts data into throughput_thresholds
  # This is used for one time run in a DB. There should be only 5 records in the
  # table throughput_thresholds. After insertion only updation should happen to these 5 rows.
  # Run as reports:insert_throughput_threshold
  task :insert_throughput_threshold => :environment do
    puts "Starting populating data for throughput thresholds"


    begin
      query = "
    INSERT INTO throughput_thresholds (process_name, threshold_tolerance, threshold_duration, created_at, updated_at)
    VALUES('Lockbox Loading', 20, '02:00:00', NOW(), NOW()),
    ('Claim Loading', 20, '02:00:00', NOW(), NOW()),
    ('Keying', 20, '02:00:00', NOW(), NOW()),
    ('QA', 20, '02:00:00', NOW(), NOW()),
    ('Output Generation', 20, '02:00:00', NOW(), NOW())
      "
      connection = ActiveRecord::Base.connection()
      connection.execute "SET autocommit=0"
      connection.begin_db_transaction
      connection.execute(query)
      connection.commit_db_transaction
      puts "The throughput threshold data is loaded into the DB"
    rescue Exception => e
      puts "The error is..................................................."
      puts e.inspect 
      puts "The transaction is rolled back as there is an exception........................"
    end
    
  end

  #   This inserts data into throughput_reports
  #   This creates the master(to be used without filter) and children(to be used with filters) records
  #   Run as reports:insert_throughput_summary
  #
  #   This provides you with information about the various processing status of the system.
  #   This is run at particular intervals by a cron
  #   The throughput_reports is cleaned up every time this runs and inserts new records real time.
  #   The existing records in throughput_reports have current data point as 1.
  #   The new records are given a current data point as 0.
  #   Then records with current as 1 are deleted. Thus the old records are deleted.
  #   The exisitng (new) records are given the current as 1.
  #   The Report UI should obtian the data with current as 1.

  #   There are 5 processes : Lockbox Loading, Claim Loading, Keying, QA, Output Generation
  #   This will generate report data such as given below for the 5 processes.
  #   (queue_volume, processing_volume, completed_volume,
  #     threshold_tolerance, current_tolerance, breached_time, threshold_duration,
  #     current_duration, STATUS, current, arrival_date, order_number)
  #   The report is generated with data of batches having minimum arrival date of its inbound file which are eligible to be in the 5 process.
  #     That is minimum arrival date with which report is generated =
  #     minimum arrival date of batches having batches.status as 'NEW' or 'PROCESSING' or 'OUTPUT_READY' or 'OUTPUT_GENERATING' or
  #     batches.qa_status as 'ALLOCATED' or inbound_file_informations.status = 'Loading'
  #
  #   Explanation of report data :
  #
  #   Item for the 5 processes :
  #   Lockbox Loading : Lockbox inbound file from inbound_file_informations[file_type = 'LOCKBOX']
  #   Claim Loading : Claim inbound file from inbound_file_informations[file_type = 'CLAIM']
  #   Keying : Batches from table batches
  #   QA : Batches from table batches
  #   Output Generation : Batches from table batches
  #   Items are collected from a particular arrival_time of inbound file from inbound_file_informations
  #
  #   queue_volume : Number of items ready to be processed
  #   queue_volume of the 5 processes
  #       Lockbox Loading :  count of inbound_file_informations having inbound_file_informations.status = 'ARRIVED', inbound_file_informations.file_type = 'LOCKBOX'
  #       Claim Loading : count of inbound_file_informations having inbound_file_informations.status = 'ARRIVED', inbound_file_informations.file_type = 'CLAIM'
  #       Keying : count of batches having batches.status = 'NEW'
  #       QA : count of batches having batches.qa_status = 'ALLOCATED'
  #       Output Generation : count of batches having batches.status = 'OUTPUT_READY'
  #
  #   processing_volume : Number of items getting processed
  #   processing_volume of the 5 processes
  #       Lockbox Loading :  count of inbound_file_informations having inbound_file_informations.status = 'LOADING', inbound_file_informations.file_type = 'LOCKBOX'
  #       Claim Loading : count of inbound_file_informations having inbound_file_informations.status = 'LOADING', inbound_file_informations.file_type = 'CLAIM'
  #       Keying : count of batches having batches.status = 'PROCESSING'
  #       QA : count of batches having batches.qa_status = 'PROCESSING'
  #       Output Generation : count of batches having batches.status = 'OUTPUT_GENERATING'
  #
  #   completed_volume : Number of items that completed the process
  #   completed_volume of the 5 processes
  #       Lockbox Loading :  count of inbound_file_informations having inbound_file_informations.status = 'LOADED', inbound_file_informations.file_type = 'LOCKBOX'
  #       Claim Loading : count of inbound_file_informations having inbound_file_informations.status = 'LOADED', inbound_file_informations.file_type = 'CLAIM'
  #       Keying : count of batches having batches.status = 'COMPLETED' OR 'OUTPUT_READY' OR 'OUTPUT_GENERATING' OR 'OUTPUT_GENERATED'
  #       QA : count of batches having batches.qa_status = 'COMPLETED'
  #       Output Generation : count of batches having batches.status = 'OUTPUT_GENERATED'
  #
  #   threshold_tolerance : The threshold value for the tolerance of system to meet the expected results.
  #   current_tolerance : Percentage of items to complete
  #
  #   breached_time : Time when the system breached the threshold value for tolerance
  #
  #   threshold_duration : The threshold value for the duration of system after breach time to meet the expected results.
  #   current_duration : Time exceeded after the system breach of threshold_tolerance :
  #
  #   status : Status of the system indicating the progress of the 5 processes.
  #    There are 3 status : 'As Expected', 'Backlogged - Below Threshold', 'Backlogged - Exceeded Threshold'
  #
  #   current_tolerance : (queue_volume / (queue_volume + processing_volume)) * 100
  #   initial_breached_time : indicates breached_time for the process is stored in throughput_report_breached_informations
  #   breached_time =
  #                    IF current_tolerance = 0
  #                     THEN NULL
  #                    ELSE IF initial_breached_time is not NULL
  #                     THEN initial_breached_time
  #                    ELSE IF current_tolerance > threshold_tolerance
  #                     THEN CURTIME()
  #                    ELSE
  #                     NULL
  #                    END
  #
  #   current_duration : Current Time - breached_time
  #   status =
  #           IF breached_time = NULL
  #            THEN 'AS Expected'
  #           ELSE IF current_duration < threshold_duration
  #            THEN 'Backlogged - Below Threshold'
  #           ELSE IF current_duration > threshold_duration
  #            THEN 'Backlogged - Exceeds Threshold'
  #           END

  desc "To populate the data for throughput report."
  task :insert_throughput_summary => :environment do

    # Log for Throughput Summary
    report = RevRemitLogger.new_logger(LogLocation::TSLOG)
    
    time_in_est = Time.now().in_time_zone('Eastern Time (US & Canada)')
    time_difference_of_est_from_utc = time_in_est.strftime("%z")
    time_difference_of_est_from_utc = time_difference_of_est_from_utc[0 .. 2] + ':' + time_difference_of_est_from_utc[3, 4]

    batch_with_min_arrived_date_of_lockbox_loading = Batch.find_by_sql("
      SELECT MIN(inputs.arrival_time) as arrival_time
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE batches.status IN ('Arrived', 'Loading') AND inputs.file_type = 'Lockbox'")
    
    batch_with_min_arrived_date_of_claim_loading = Batch.find_by_sql("
      SELECT MIN(inputs.arrival_time) as arrival_time
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE batches.status IN ('Arrived', 'Loading') AND inputs.file_type = 'Claim'")

    batch_with_min_arrived_date_of_keying = Batch.find_by_sql("
      SELECT MIN(inputs.arrival_time) as arrival_time
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE batches.status IN ('#{BatchStatus::NEW}', '#{BatchStatus::PROCESSING}')")
    
    batch_with_min_arrived_date_of_qa = Batch.find_by_sql("
      SELECT MIN(inputs.arrival_time) as arrival_time
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE batches.qa_status IN ('#{QaStatus::ALLOCATED}', '#{QaStatus::PROCESSING}')")
    
    batch_with_min_arrived_date_of_output_generation = Batch.find_by_sql("
      SELECT MIN(inputs.arrival_time) as arrival_time
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE batches.status IN ('#{BatchStatus::OUTPUT_READY}', '#{BatchStatus::OUTPUT_GENERATING}')")

    array_of_minimum_date_of_processes = [batch_with_min_arrived_date_of_lockbox_loading.first.arrival_time,
      batch_with_min_arrived_date_of_claim_loading.first.arrival_time,
      batch_with_min_arrived_date_of_keying.first.arrival_time,
      batch_with_min_arrived_date_of_qa.first.arrival_time,
      batch_with_min_arrived_date_of_output_generation.first.arrival_time
    ]
    minimum_date_to_fetch_batches = array_of_minimum_date_of_processes.compact.sort.first
    minimum_date_to_fetch_batches = minimum_date_to_fetch_batches.to_s.split(' ')[0]
       
    
    report.debug "Minimum Date To Fetch Batches : #{minimum_date_to_fetch_batches}"
    
    lockbox_loading_threshold_tolerance = nil
    claim_loading_threshold_tolerance = nil
    keying_threshold_tolerance = nil    
    qa_threshold_tolerance = nil
    output_generation_threshold_tolerance = nil
    
    lockbox_loading_threshold_duration = nil
    claim_loading_threshold_duration = nil
    keying_threshold_duration = nil
    qa_threshold_duration = nil
    output_generation_threshold_duration = nil

    lockbox_loading_breached_time = nil
    claim_loading_breached_time = nil
    keying_breached_time = nil
    qa_breached_time = nil
    output_generation_breached_time = nil

    thresholds = ThroughputThreshold.find(:all, :select => ["process_name, threshold_tolerance, threshold_duration"])
    thresholds.each do |threshold|
      threshold_duration = threshold.threshold_duration.to_s.split(' ')[1]
      case threshold.process_name.to_s
      when 'Lockbox Loading'
        lockbox_loading_threshold_tolerance = threshold.threshold_tolerance
        lockbox_loading_threshold_duration = threshold_duration
      when 'Claim Loading'
        claim_loading_threshold_tolerance = threshold.threshold_tolerance
        claim_loading_threshold_duration = threshold_duration
      when 'Keying'
        keying_threshold_tolerance = threshold.threshold_tolerance
        keying_threshold_duration = threshold_duration
      when 'QA'
        qa_threshold_tolerance = threshold.threshold_tolerance
        qa_threshold_duration = threshold_duration
      when 'Output Generation'
        output_generation_threshold_tolerance = threshold.threshold_tolerance
        output_generation_threshold_duration = threshold_duration
      end
    end

    breached_informations = ThroughputReportBreachedInformation.find(:all, :select => ["process_name, breached_time"])
    breached_informations.each do |row|
      breached_time_in_array = row.breached_time.to_s.split(' ')
      if !breached_time_in_array.blank?
        breached_time = breached_time_in_array[0] + ' ' + breached_time_in_array[1]
      end

      case row.process_name.to_s
      when 'Lockbox Loading'
        lockbox_loading_breached_time = breached_time
      when 'Claim Loading'
        claim_loading_breached_time = breached_time
      when 'Keying'
        keying_breached_time = breached_time
      when 'QA'
        qa_breached_time = breached_time
      when 'Output Generation'
        output_generation_breached_time = breached_time
      end
    end

    lockbox_loading_breached_time = 'NULL' if lockbox_loading_breached_time.blank?
    claim_loading_breached_time = 'NULL' if claim_loading_breached_time.blank?
    keying_breached_time = 'NULL' if keying_breached_time.blank?
    qa_breached_time = 'NULL' if qa_breached_time.blank?
    output_generation_breached_time = 'NULL' if output_generation_breached_time.blank?

    initial_lockbox_loading_breached_time = lockbox_loading_breached_time
    initial_claim_loading_breached_time = claim_loading_breached_time
    initial_keying_breached_time = keying_breached_time
    initial_qa_breached_time = qa_breached_time
    initial_output_generation_breached_time = output_generation_breached_time

   
    queries = Array.new
    #    -- *********************** Master Records ***************


    #-- ***************** Master Lockbox Loading ********************
    if !lockbox_loading_threshold_tolerance.blank? && !lockbox_loading_threshold_duration.blank?


      lockbox_loading_queue_volume = "CASE WHEN (SUM( IF(input_files.status = 'Arrived', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Arrived', 1, 0))) END"
      lockbox_loading_processing_volume = "CASE WHEN (SUM( IF(input_files.status = 'Loading', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Loading', 1, 0))) END"
      lockbox_loading_completed_volume = "CASE WHEN (SUM( IF(input_files.status = 'Loaded', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Loaded', 1, 0))) END"

      lockbox_loading_current_tolerance =
        "CASE
          WHEN #{lockbox_loading_queue_volume} = 0 OR #{lockbox_loading_queue_volume} IS NULL OR
            (#{lockbox_loading_queue_volume} + #{lockbox_loading_processing_volume}) = 0
            THEN 0
          ELSE
            (#{lockbox_loading_queue_volume} / (#{lockbox_loading_queue_volume} + #{lockbox_loading_processing_volume}) ) * 100
        END"
      
      lockbox_loading_breached_time =
        "CASE
          WHEN #{lockbox_loading_current_tolerance} = 0
            THEN NULL
          WHEN '#{lockbox_loading_breached_time}' != 'NULL'
            THEN '#{lockbox_loading_breached_time}'
          WHEN #{lockbox_loading_current_tolerance} > #{lockbox_loading_threshold_tolerance}
            THEN NOW()
          ELSE NULL
        END"
      
      lockbox_loading_current_duration = "TIMEDIFF(NOW(), #{lockbox_loading_breached_time})"

      lockbox_loading_status =
        "CASE
        WHEN
          (CASE
              WHEN #{lockbox_loading_current_tolerance} = 0
                THEN NULL
              WHEN '#{initial_lockbox_loading_breached_time}' != 'NULL'
                THEN 1
              WHEN #{lockbox_loading_current_tolerance} > #{lockbox_loading_threshold_tolerance}
                THEN NOW()
              ELSE NULL
            END) is NULL
        THEN 'As Expected'
        WHEN #{lockbox_loading_current_duration} < '#{lockbox_loading_threshold_duration}'
        THEN 'Backlogged - Below Threshold'
        WHEN #{lockbox_loading_current_duration} >= '#{lockbox_loading_threshold_duration}'
        THEN 'Backlogged - Exceeds Threshold'
        END"
      
      queries <<
        "
    INSERT INTO throughput_reports
          (process_name, queue_volume, processing_volume, completed_volume,
           threshold_tolerance, current_tolerance, breached_time, threshold_duration,
            current_duration, STATUS, current, created_at, updated_at, arrival_date, order_number)

    SELECT 'Lockbox Loading',
     #{lockbox_loading_queue_volume} AS queue_volume,
     #{lockbox_loading_processing_volume} AS processing_volume,
     #{lockbox_loading_completed_volume} AS completed_volume,
     #{lockbox_loading_threshold_tolerance} AS threshold_tolerance,
     #{lockbox_loading_current_tolerance} AS current_tolerance,
     #{lockbox_loading_breached_time} AS breached_time,
     '#{lockbox_loading_threshold_duration}' AS threshold_duration,
     #{lockbox_loading_current_duration} AS current_duration,
     #{lockbox_loading_status} AS STATUS,

     0 AS current, NOW() AS created_at, NOW() AS updated_at, NOW() AS arrival_date, 1 AS order_number
    FROM inbound_file_informations AS input_files
    WHERE input_files.file_type = 'Lockbox' AND input_files.arrival_time >= #{minimum_date_to_fetch_batches}
      AND input_files.is_nullfile = 0
      "
    else
      report.error "Threshold tolerance or threshold duration for Lockbox Loading is missing."
    end

    #-- ***************** Master Claim Loading ********************
    if !claim_loading_threshold_tolerance.blank? && !claim_loading_threshold_duration.blank?

      claim_loading_queue_volume = "CASE WHEN (SUM( IF(input_files.status = 'Arrived', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Arrived', 1, 0))) END"
      claim_loading_processing_volume = "CASE WHEN (SUM( IF(input_files.status = 'Loading', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Loading', 1, 0))) END"
      claim_loading_completed_volume = "CASE WHEN (SUM( IF(input_files.status = 'Loaded', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(input_files.status = 'Loaded', 1, 0))) END"

      claim_loading_current_tolerance =
        "CASE
           WHEN #{claim_loading_queue_volume} = 0 OR #{claim_loading_queue_volume} IS NULL OR
            (#{claim_loading_queue_volume} + #{claim_loading_processing_volume}) = 0
           THEN 0
           ELSE
            (#{claim_loading_queue_volume} / (#{claim_loading_queue_volume} + #{claim_loading_processing_volume}) ) * 100
         END"

      claim_loading_breached_time =
        "CASE
          WHEN #{claim_loading_current_tolerance} = 0
            THEN NULL
          WHEN '#{claim_loading_breached_time}' != 'NULL'
            THEN '#{claim_loading_breached_time}'
          WHEN #{claim_loading_current_tolerance} > #{claim_loading_threshold_tolerance}
            THEN NOW()
          ELSE NULL
        END"

      claim_loading_current_duration = "TIMEDIFF(NOW(), #{claim_loading_breached_time})"

      claim_loading_status =
        "CASE
        WHEN
          (CASE
              WHEN #{claim_loading_current_tolerance} = 0
                THEN NULL
              WHEN '#{initial_claim_loading_breached_time}' != 'NULL'
                THEN 1
              WHEN #{claim_loading_current_tolerance} > #{claim_loading_threshold_tolerance}
                THEN NOW()
              ELSE NULL
            END) is NULL
        THEN 'As Expected'
        WHEN #{claim_loading_current_duration} < '#{claim_loading_threshold_duration}'
        THEN 'Backlogged - Below Threshold'
        WHEN #{claim_loading_current_duration} >= '#{claim_loading_threshold_duration}'
        THEN 'Backlogged - Exceeds Threshold'
        END"

      queries <<
        "
    INSERT INTO throughput_reports
          (process_name, queue_volume, processing_volume, completed_volume,
           threshold_tolerance, current_tolerance, breached_time, threshold_duration,
            current_duration, STATUS, current, created_at, updated_at, arrival_date, order_number)

    SELECT 'Claim Loading',
     #{claim_loading_queue_volume} AS queue_volume,
     #{claim_loading_processing_volume} AS processing_volume,
     #{claim_loading_completed_volume} AS completed_volume,
     #{claim_loading_threshold_tolerance} AS threshold_tolerance,
     #{claim_loading_current_tolerance} AS current_tolerance,
     #{claim_loading_breached_time} AS breached_time,
     '#{claim_loading_threshold_duration}' AS threshold_duration,
     #{claim_loading_current_duration} AS current_duration,
     #{claim_loading_status} AS STATUS,

     0 AS current, NOW() AS created_at, NOW() AS updated_at, NOW() AS arrival_date, 2 AS order_number
    FROM inbound_file_informations AS input_files
    WHERE input_files.file_type = 'Claim' AND input_files.arrival_time >= #{minimum_date_to_fetch_batches}
      AND input_files.is_nullfile = 0
      "
    else
      report.error "Threshold tolerance or threshold duration for Lockbox Loading is missing."
    end
    
    #--  ******************** Master Keying ******************
    if !keying_threshold_tolerance.blank? && !keying_threshold_duration.blank?


      keying_queue_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::NEW}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::NEW}', 1, 0))) END"
      keying_processing_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::PROCESSING}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::PROCESSING}', 1, 0))) END"
      keying_completed_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::COMPLETED}' OR batches.status = '#{BatchStatus::OUTPUT_READY}'
        OR batches.status = '#{BatchStatus::OUTPUT_GENERATING}' OR batches.status = '#{BatchStatus::OUTPUT_GENERATED}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::COMPLETED}' OR batches.status = '#{BatchStatus::OUTPUT_READY}'
        OR batches.status = '#{BatchStatus::OUTPUT_GENERATING}' OR batches.status = '#{BatchStatus::OUTPUT_GENERATED}', 1, 0))) END"

      keying_current_tolerance =
        "CASE
           WHEN #{keying_queue_volume} = 0 OR #{keying_queue_volume} IS NULL OR
            (#{keying_queue_volume} + #{keying_processing_volume}) = 0
           THEN 0
           ELSE
            (#{keying_queue_volume} / (#{keying_queue_volume} + #{keying_processing_volume}) ) * 100
         END"

      keying_breached_time =
        "CASE
          WHEN #{keying_current_tolerance} = 0
            THEN NULL
          WHEN '#{keying_breached_time}' != 'NULL'
            THEN '#{keying_breached_time}'
          WHEN #{keying_current_tolerance} > #{keying_threshold_tolerance}
            THEN NOW()
          ELSE NULL
        END"

      keying_current_duration = "TIMEDIFF(NOW(), #{keying_breached_time})"

      keying_status =
        "CASE
        WHEN
          (CASE
              WHEN #{keying_current_tolerance} = 0
                THEN NULL
              WHEN '#{initial_keying_breached_time}' != 'NULL'
                THEN 1
              WHEN #{keying_current_tolerance} > #{keying_threshold_tolerance}
                THEN NOW()
              ELSE NULL
            END) is NULL
        THEN 'As Expected'
        WHEN #{keying_current_duration} < '#{keying_threshold_duration}'
        THEN 'Backlogged - Below Threshold'
        WHEN #{keying_current_duration} >= '#{keying_threshold_duration}'
        THEN 'Backlogged - Exceeds Threshold'
        END"

      queries <<
        "
        INSERT INTO throughput_reports
              (process_name, queue_volume, processing_volume, completed_volume,
               threshold_tolerance, current_tolerance, breached_time, threshold_duration,
                current_duration, STATUS, current, created_at, updated_at, arrival_date, order_number)

        SELECT 'Keying',
         #{keying_queue_volume} AS queue_volume,
         #{keying_processing_volume} AS processing_volume,
         #{keying_completed_volume} AS completed_volume,
         #{keying_threshold_tolerance} AS threshold_tolerance,
         #{keying_current_tolerance} AS current_tolerance,
         #{keying_breached_time} AS breached_time,
         '#{keying_threshold_duration}' AS threshold_duration,
         #{keying_current_duration} AS current_duration,
         #{keying_status} AS STATUS,

         0 AS current, NOW() AS created_at, NOW() AS updated_at, NOW() AS arrival_date, 3 AS order_number
        FROM batches
        INNER JOIN inbound_file_informations AS inputs ON inputs.id = batches.inbound_file_information_id
        WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0

      "
    else
      report.error "Threshold tolerance or threshould duration for Keying is missing."
    end

    #--  ******************** Master QA ******************
    if !qa_threshold_tolerance.blank? && !qa_threshold_duration.blank?

      qa_queue_volume = "CASE WHEN (SUM( IF(batches.qa_status = '#{QaStatus::ALLOCATED}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.qa_status = '#{QaStatus::ALLOCATED}', 1, 0))) END"
      qa_processing_volume = "CASE WHEN (SUM( IF(batches.qa_status = '#{QaStatus::PROCESSING}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.qa_status = '#{QaStatus::PROCESSING}', 1, 0))) END"
      qa_completed_volume = "CASE WHEN (SUM( IF(batches.qa_status = '#{QaStatus::COMPLETED}' OR batches.status = '#{BatchStatus::OUTPUT_READY}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.qa_status = '#{QaStatus::COMPLETED}', 1, 0))) END"

      qa_current_tolerance =
        "CASE
         WHEN #{qa_queue_volume} = 0 OR #{qa_queue_volume} IS NULL OR
          (#{qa_queue_volume} + #{qa_processing_volume}) = 0
         THEN 0
         ELSE
         (#{qa_queue_volume} / (#{qa_queue_volume} + #{qa_processing_volume}) ) * 100
      END"

      qa_breached_time =
        "CASE
          WHEN #{qa_current_tolerance} = 0
            THEN NULL
          WHEN '#{qa_breached_time}' != 'NULL'
            THEN '#{qa_breached_time}'
          WHEN #{qa_current_tolerance} > #{qa_threshold_tolerance}
            THEN NOW()
          ELSE NULL
        END"

      qa_current_duration = "TIMEDIFF(NOW(), #{qa_breached_time})"

      qa_status =
        "CASE
        WHEN
          (CASE
            WHEN #{qa_current_tolerance} = 0
              THEN NULL
              WHEN '#{initial_qa_breached_time}' != 'NULL'
                THEN 1
              WHEN #{qa_current_tolerance} > #{qa_threshold_tolerance}
                THEN NOW()
              ELSE NULL
            END) is NULL
        THEN 'As Expected'
        WHEN #{qa_current_duration} < '#{qa_threshold_duration}'
        THEN 'Backlogged - Below Threshold'
        WHEN #{qa_current_duration} >= '#{qa_threshold_duration}'
        THEN 'Backlogged - Exceeds Threshold'
        END"
      
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, breached_time, threshold_duration,
             current_duration, STATUS, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'QA',
       #{qa_queue_volume} AS queue_volume,
       #{qa_processing_volume} AS processing_volume,
       #{qa_completed_volume} AS completed_volume,
       #{qa_threshold_tolerance} AS threshold_tolerance,
       #{qa_current_tolerance} AS current_tolerance,
       #{qa_breached_time} AS breached_time,
       '#{qa_threshold_duration}' AS threshold_duration,
       #{qa_current_duration} AS current_duration,
       #{qa_status} AS STATUS,

       0 AS current, NOW() AS created_at, NOW() AS updated_at, NOW() AS arrival_date, 4 AS order_number
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON inputs.id = batches.inbound_file_information_id
      WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0
      "
    else
      report.error "Threshold tolerance or threshold duration for QA is missing."
    end

    #  -- ***************************** Master Output Generation**************************
    if !output_generation_threshold_tolerance.blank? && !output_generation_threshold_duration.blank?

      output_generation_queue_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_READY}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_READY}', 1, 0))) END"
      output_generation_processing_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_GENERATING}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_GENERATING}', 1, 0))) END"
      output_generation_completed_volume = "CASE WHEN (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_GENERATED}', 1, 0))) IS NULL
        THEN 0 ELSE (SUM( IF(batches.status = '#{BatchStatus::OUTPUT_GENERATED}', 1, 0))) END"

      output_generation_current_tolerance =
        "CASE
       WHEN #{output_generation_queue_volume} = 0 OR #{output_generation_queue_volume} IS NULL OR
        (#{output_generation_queue_volume} + #{output_generation_processing_volume}) = 0
       THEN 0
       ELSE
       (#{output_generation_queue_volume} / (#{output_generation_queue_volume} + #{output_generation_processing_volume}) ) * 100
      END"

      output_generation_breached_time =
        "CASE
          WHEN #{output_generation_current_tolerance} = 0
            THEN NULL
          WHEN '#{output_generation_breached_time}' != 'NULL'
            THEN '#{output_generation_breached_time}'
          WHEN #{output_generation_current_tolerance} > #{output_generation_threshold_tolerance}
            THEN NOW()
          ELSE NULL
        END"
      
      output_generation_current_duration = "TIMEDIFF(NOW(), #{output_generation_breached_time})"
      
      output_generation_status =
        "CASE
        WHEN
          (CASE
              WHEN #{output_generation_current_tolerance} = 0
                THEN NULL
              WHEN '#{initial_output_generation_breached_time}' != 'NULL'
                THEN 1
              WHEN #{output_generation_current_tolerance} > #{output_generation_threshold_tolerance}
                THEN NOW()
              ELSE NULL
            END) is NULL
        THEN 'As Expected'
        WHEN #{output_generation_current_duration} < '#{output_generation_threshold_duration}'
        THEN 'Backlogged - Below Threshold'
        WHEN #{output_generation_current_duration} >= '#{output_generation_threshold_duration}'
        THEN 'Backlogged - Exceeds Threshold'
        END"

      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, breached_time, threshold_duration,
              current_duration, STATUS, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'Output Generation',
       #{output_generation_queue_volume} AS queue_volume,
       #{output_generation_processing_volume} AS processing_volume,
       #{output_generation_completed_volume} AS completed_volume,
       #{output_generation_threshold_tolerance} AS threshold_tolerance,
       #{output_generation_current_tolerance} AS current_tolerance,
       #{output_generation_breached_time} AS breached_time,
       '#{output_generation_threshold_duration}' AS threshold_duration,
       #{output_generation_current_duration} AS current_duration,
       #{output_generation_status} AS STATUS,

       0 AS current, NOW() AS created_at, NOW() AS updated_at, NOW() AS arrival_date, 5 AS order_number
      FROM batches
      INNER JOIN inbound_file_informations AS inputs ON inputs.id = batches.inbound_file_information_id
      WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0
      "
    else
      report.error "Threshold tolerance or threshold duration for Output Generation is missing."
    end
    
    #-- *********************** Child Records ***************

    #-- ******************************** Lockbox Loading ******************
    if !lockbox_loading_threshold_tolerance.blank? && !lockbox_loading_threshold_duration.blank?
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, threshold_duration,
             partner_name, client_name, client_id, facility_name, facility_id,
             lockbox_name, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'Lockbox Loading',
       #{lockbox_loading_queue_volume} AS queue_volume,
       #{lockbox_loading_processing_volume} AS processing_volume,
       #{lockbox_loading_completed_volume} AS completed_volume,
       #{lockbox_loading_threshold_tolerance} AS threshold_tolerance,
       #{lockbox_loading_current_tolerance} AS current_tolerance,
       '#{lockbox_loading_threshold_duration}' AS threshold_duration,

        facilities.index_file_parser_type AS partner_name,
        clients.name AS client_name, clients.id AS client_id,
        facilities.name AS facility_name, facilities.id AS facility_id,
        input_files.lockbox_name AS lockbox_name,
         0 AS current, NOW() AS created_at, NOW() AS updated_at,
         DATE(CONVERT_TZ(input_files.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}')) AS arrival_date,
         1 AS order_number
      FROM inbound_file_informations AS input_files
      INNER JOIN facilities ON facilities.id = input_files.facility_id
      INNER JOIN clients ON facilities.client_id = clients.id
      WHERE input_files.file_type = 'Lockbox' AND input_files.arrival_time >= #{minimum_date_to_fetch_batches}
          AND input_files.is_nullfile = 0
      GROUP BY input_files.lockbox_name, DATE(CONVERT_TZ(input_files.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}'))
      "
    else
      report.error "Threshold tolerance or threshold duration for Lockbox Loading is missing."
    end

    #-- ******************************** Claim Loading ******************
    if !claim_loading_threshold_tolerance.blank? && !claim_loading_threshold_duration.blank?
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, threshold_duration,
             partner_name, client_name, client_id, facility_name, facility_id,
             lockbox_name, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'Claim Loading',

       #{claim_loading_queue_volume} AS queue_volume,
       #{claim_loading_processing_volume} AS processing_volume,
       #{claim_loading_completed_volume} AS completed_volume,
       #{claim_loading_threshold_tolerance} AS threshold_tolerance,
       #{claim_loading_current_tolerance} AS current_tolerance,
       '#{claim_loading_threshold_duration}' AS threshold_duration,

        facilities.index_file_parser_type AS partner_name,
        clients.name AS client_name, clients.id AS client_id,
        facilities.name AS facility_name, facilities.id AS facility_id,
        input_files.lockbox_name AS lockbox_name,
         0 AS current, NOW() AS created_at, NOW() AS updated_at,
         DATE(CONVERT_TZ(input_files.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}')) AS arrival_date,
        2 AS order_number
      FROM inbound_file_informations AS input_files
      INNER JOIN facilities ON facilities.id = input_files.facility_id
      INNER JOIN clients ON facilities.client_id = clients.id
      WHERE input_files.file_type = 'Claim' AND input_files.arrival_time >= #{minimum_date_to_fetch_batches}
          AND input_files.is_nullfile = 0
      GROUP BY input_files.lockbox_name, DATE(CONVERT_TZ(input_files.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}'))
      "
    else
      report.error "Threshold tolerance or threshold duration for Lockbox Loading is missing."
    end


    #--  ******************** Keying ******************
    if !keying_threshold_tolerance.blank? && !keying_threshold_duration.blank?
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, threshold_duration,
             partner_name, client_name, client_id, facility_name, facility_id,
             lockbox_name, batch_type, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'Keying',
       #{keying_queue_volume} AS queue_volume,
       #{keying_processing_volume} AS processing_volume,
       #{keying_completed_volume} AS completed_volume,
       #{keying_threshold_tolerance} AS threshold_tolerance,
       #{keying_current_tolerance} AS current_tolerance,
       '#{keying_threshold_duration}' AS threshold_duration,

        facilities.index_file_parser_type AS partner_name,
        clients.name AS client_name, clients.id AS client_id,
        facilities.name AS facility_name, facilities.id AS facility_id,
        inputs.lockbox_name AS lockbox_name,
        CASE 1
          WHEN batches.correspondence = 0
            THEN 'Payment'
          WHEN batches.correspondence = 1
            THEN 'Correspondence'
          WHEN batches.correspondence IS NULL
            THEN 'Both'
          END AS batch_type,
        0 AS current, NOW() AS created_at, NOW() AS updated_at,
        DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}')) AS arrival_date,
        3 AS order_number

      FROM batches
      INNER JOIN facilities ON facilities.id = batches.facility_id
      INNER JOIN clients ON facilities.client_id = clients.id
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0
      GROUP BY batch_type, inputs.lockbox_name, DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}'))

      "
    else
      report.error "Threshold tolerance or threshold duration for Keying is missing."
    end

    #-- ************************* QA *********************************
    if !qa_threshold_tolerance.blank? && !qa_threshold_duration.blank?
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, threshold_duration,
             partner_name, client_name, client_id, facility_name, facility_id,
             lockbox_name, batch_type, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'QA',
       #{qa_queue_volume} AS queue_volume,
       #{qa_processing_volume} AS processing_volume,
       #{qa_completed_volume} AS completed_volume,
       #{qa_threshold_tolerance} AS threshold_tolerance,
       #{qa_current_tolerance} AS current_tolerance,
       '#{qa_threshold_duration}' AS threshold_duration,

        facilities.index_file_parser_type AS partner_name,
        clients.name AS client_name, clients.id AS client_id,
        facilities.name AS facility_name, facilities.id AS facility_id,
        inputs.lockbox_name AS lockbox_name,
        CASE 1
          WHEN batches.correspondence = 0
            THEN 'Payment'
          WHEN batches.correspondence = 1
            THEN 'Correspondence'
          WHEN batches.correspondence IS NULL
            THEN 'Both'
        END AS batch_type,
        0 AS current, NOW() AS created_at, NOW() AS updated_at,
        DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}')) AS arrival_date,
        4 AS order_number

      FROM batches
      INNER JOIN facilities ON facilities.id = batches.facility_id
      INNER JOIN clients ON facilities.client_id = clients.id
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0
      GROUP BY batch_type, inputs.lockbox_name, DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}'))

      "
    else
      report.error "Threshold tolerance or threshold duration for QA is missing."
    end

    #-- ****************************** Output Generation **********************
    if !output_generation_threshold_tolerance.blank? && !output_generation_threshold_duration.blank?
      queries <<
        "
      INSERT INTO throughput_reports
            (process_name, queue_volume, processing_volume, completed_volume,
             threshold_tolerance, current_tolerance, threshold_duration,
             partner_name, client_name, client_id, facility_name, facility_id,
             lockbox_name, batch_type, current, created_at, updated_at, arrival_date, order_number)

      SELECT 'Output Generation',
       #{output_generation_queue_volume} AS queue_volume,
       #{output_generation_processing_volume} AS processing_volume,
       #{output_generation_completed_volume} AS completed_volume,
       #{output_generation_threshold_tolerance} AS threshold_tolerance,
       #{output_generation_current_tolerance} AS current_tolerance,
       '#{output_generation_threshold_duration}' AS threshold_duration,

        facilities.index_file_parser_type AS partner_name,
        clients.name AS client_name, clients.id AS client_id,
        facilities.name AS facility_name, facilities.id AS facility_id,
        inputs.lockbox_name AS lockbox_name,
        CASE 1
          WHEN batches.correspondence = 0
            THEN 'Payment'
          WHEN batches.correspondence = 1
            THEN 'Correspondence'
          WHEN batches.correspondence IS NULL
            THEN 'Both'
        END AS batch_type,
        0 AS current, NOW() AS created_at, NOW() AS updated_at, 
        DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}')) AS arrival_date,
        5 AS order_number

      FROM batches
      INNER JOIN facilities ON facilities.id = batches.facility_id
      INNER JOIN clients ON facilities.client_id = clients.id
      INNER JOIN inbound_file_informations AS inputs ON batches.inbound_file_information_id = inputs.id
      WHERE inputs.arrival_time >= #{minimum_date_to_fetch_batches}
          AND inputs.is_nullfile = 0
      GROUP BY batch_type, inputs.lockbox_name, DATE(CONVERT_TZ(inputs.arrival_time, '+00:00', '#{time_difference_of_est_from_utc}'))

      "
    else
      report.error "Threshold tolerance or threshold duration for Output Generation is missing."
    end

    

    queries << " DELETE FROM throughput_reports WHERE current = 1 "    

    queries << " TRUNCATE throughput_report_breached_informations "
    
    queries << " INSERT INTO throughput_report_breached_informations (process_name, breached_time, updated_at)
    SELECT throughput_reports.process_name, throughput_reports.breached_time, NOW()
    FROM throughput_reports
    WHERE client_id IS NULL AND facility_id IS NULL
    GROUP BY throughput_reports.process_name "

    queries << " INSERT INTO throughput_reports (process_name, arrival_date, current, order_number)
      SELECT 'MASTER', MIN(arrival_date) AS arrival_date, 0, 6
      FROM throughput_reports"
    
    queries << " UPDATE throughput_reports SET current = 1 "

    # used to connect active record to the database
    begin
      report.debug "The query to insert data as follows "
      report.debug "#{queries}"
      report.debug "Starting the transaction of inserting data into DB."
      connection = ActiveRecord::Base.connection()
      connection.execute "SET autocommit=0"
      connection.begin_db_transaction
      for query in queries
        connection.execute(query)
      end
      connection.commit_db_transaction
      puts "The throughput report data is loaded into the DB"
    rescue Exception => e
      puts "The error is..................................................."
      puts e.inspect
      report.error "An error has occured while inserting data."
      report.error "#{e.inspect}"
      puts "The transaction is rolled back as there is an exception........................"
    end
  end
end
