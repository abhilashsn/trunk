require 'csv'

namespace :output do
  desc "generates output files"
  task :generate, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      batches_for_output = batch.batch_bundle
      batches_for_output.map{|b| b.update_attribute(:output_835_start_time, Time.now)}
      batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      cgf = CheckGroupFile.new(batches_for_output.first.facility)
      cgf.send_later :process_batch_ids, batch_ids, batch_ids_for_supplemental_output
      #oplog  =   OperationLog::Generator.new(batch.id)
      #oplog.send_later :generate
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end

  desc "immediately generates output files, without using delayed job"
  task :generate_now, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      facility = batch.facility
      facility_config = facility.facility_output_configs.first
      batches_for_output = batch.batch_bundle.to_a
      batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      Batch.where(:id=>batch_ids).update_all(:output_835_start_time => Time.now)
      batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      cgf = CheckGroupFile.new(facility)
      cgf.send :process_batch_ids, batch_ids, batch_ids_for_supplemental_output
      if facility_config.details[:generate_null_835]
        batch_type_group = batches_for_output.group_by{|batch| batch.correspondence}
        cgf.generate_null_835(batch, 'PAYMENT') if batch_type_group[false].blank?
        cgf.generate_null_835(batch, 'CORRESPONDENCE') if batch_type_group[true].blank?
      end
      OperationLog::Generator.new(batch.id).generate
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end


  task :generate_files, [:batch_id, :unified_output] => :environment do |t, args|
    begin
      batch = Batch.find(args.batch_id)
      facility_details = batch.facility.details
      client = batch.client
      batch_group = batch.batch_group 'Output'
      batch_ids = batch_group.collect(&:id)
      is_output_qualified = !batch_group.detect { |batch| batch.incomplete? }
      if is_output_qualified 
        Batch.where("id in (?)", batch_ids).update_all(:output_835_start_time => Time.now,:updated_at => Time.now,:associated_entity_updated_at => Time.now )
        ack_latest_count = OutputActivityLog.get_latest_number
        check_segregator = CheckGrouper.new(batch_group, ack_latest_count, args.unified_output)
        check_segregator.segregate_checks
        #batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
        #batch_ids_for_supplemental_output = batches_for_supplemental_output.collect(&:id)
        #cgf = CheckGroupFile.new(facility)
        #cgf.send :process_batch_ids, batch_ids, batch_ids_for_supplemental_output
        #
        #Generating facility level operation log along with output generation
        #This will be generated only if client level operation log is disabled
        if client.supplemental_outputs.present? && client.supplemental_outputs.include?("Operation Log")
          puts "Operation Log is configured at client level, please uncheck that if you want facility level"
        else
          puts "Generating Operation Log at Facility Level...."
          OperationLog::Generator.new(batch_ids,ack_latest_count).generate
        end
      else
        if !is_output_qualified
          puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
        else
          puts "Batch #{batch.batchid} is not ready for output generation"
        end
      end
    rescue => e
      Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_EXCEPTION,:updated_at => Time.now,:associated_entity_updated_at => Time.now)
      puts "Output Generation failed with following errors"
      puts e.message
      puts e.backtrace
    else
      Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_GENERATED,
        :output_835_generated_time => Time.now,:updated_at => Time.now ,:associated_entity_updated_at => Time.now) if is_output_qualified
      batch.create_output_notification_file(ack_latest_count) if (is_output_qualified && 
          facility_details[:output_notification_file] == true)
    end
  end

  task :generate_adc_output, [:batch_id] => :environment do |t, args|
    begin
      batch = Batch.find(args.batch_id)
      batch_group = batch.batch_group 'Output'
      is_output_qualified = !batch_group.detect { |batch| batch.incomplete? }
      if is_output_qualified
        # todo:  && batch.qualified_for_supplimental_output_generation?
        batch_group.update_all(:output_835_start_time => Time.now)
        #ches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
        #batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
        check_segregator = CheckGrouper.new(batch_group)
        check_segregator.segregate_checks
      else
         raise "Batch #{batch.batchid} is not ready for output generation,
                  please check the status of this batch and other batches that fall into the same group for output generation"
      end
    rescue Exception => e
      batch_group.update_all(:status => BatchStatus::OUTPUT_EXCEPTION) if batch_group
      puts "Output generation failed with errors, please contact revremitsupport@revenuemed.com. "
      puts e.message
      Output835.log.error "Error => #{e.message}"
      Output835.log.error e.backtrace.join("\n")
    else
      batch_group.update_all(:status => BatchStatus::OUTPUT_GENERATED)
      Output835.log.info "Output generated sucessfully, file is written to:"
    end
  end

  desc "immediately generates output files, without using delayed job"
  task :generate_oplog_now, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      #batches_for_output = batch.batch_bundle
      #batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      #batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      #batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      OperationLog::Generator.new(batch.id).generate
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end

  desc "generates client level operation log separately"
  task :generate_client_wise_oplog, [:batch_id] => :environment do |t, args|
    begin
      batch = Batch.find(args.batch_id)
      client = batch.client
      batch_group = batch.batch_group_client_level 'Operation Log'
      if batch_group
        batch_ids = batch_group.collect(&:id)
        is_qualified_for_oplog = !batch_group.detect { |batch| batch.incomplete? }
        if is_qualified_for_oplog
          ack_latest_count = OutputActivityLog.get_latest_number
          if client.supplemental_outputs.present? && client.supplemental_outputs.include?("Operation Log")
            puts "Generating Operation Log at Client Level...."
            OperationLog::Generator.new(batch_ids,ack_latest_count).generate
          else
            puts "Operation Log is not configured at client level"
          end
        else
          puts "Batch #{batch.batchid} is not ready for operation log generation"
        end
      else
        puts "Client Level Configuration for generationg operation log not found...........\n Please configure it and try again"
      end
    rescue => e
      puts "Operation Log Generation failed with following errors"
      puts e.message
      puts e.backtrace
    end
  end

  desc "immediately generates other output files, without using delayed job"
  task :generate_other_outputs, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      #batches_for_output = batch.batch_bundle
      #batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      #batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      #batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      OtherOutput::Generator.new(batch.id).generate
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end


  
  desc "Import configurable 835segments and its options from private/configs/config_835.csv" 
  task :import_segments => :environment do
    csv_file = "#{Rails.root}/private/configs/config_835.csv"
    if FileTest.exists?(csv_file)
      FacilityLookupField.delete_all(["lookup_type = ? or lookup_type = ?", "835_SEG", "835_SEG_OPT"])
      records = CSV.read(csv_file)
      records.each do |record|
      name, lookup_type, value, category, sub_category, sort_order = record
        FacilityLookupField.create!(:name => name, :lookup_type => lookup_type, :value=>value, :category=>category, :sub_category => sub_category, :sort_order => sort_order.chomp)
      end    
      puts "\n\nImport Successful, #{records.length} records added."
    else
      puts "\n\nPlease check the file #{csv_file}"
    end
  end
  
end
