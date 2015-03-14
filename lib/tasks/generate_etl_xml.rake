namespace :etl_xml do
desc "Generates the ETL XML files"

  task :generate, [:batch_id] => :environment do |t, args|
    xml_gen = XmlGenerator.new(args.batch_id)
    if xml_gen.generate
      puts "XMLs are successfully generated and can be found in <rails_root>/private/data/XMLs"
    else
      puts "There was an error in XML generation. Refer <rails_root>/log/xml_log/XmlGeneration.log"
    end
  end

  task :generate_now, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      batches_for_output = batch.batch_bundle
      batches_for_output.map{|b| b.update_attribute(:output_835_start_time, Time.now)}
      batch_ids = OutputBatch.new.get_batchid(args.batch_id)
      batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      all_batch_ids = (batch_ids + batch_ids_for_supplemental_output).uniq
      OutputActivityLog.destroy_all "batch_id in (#{all_batch_ids.join(",")})" if all_batch_ids.present?
      Batch.update_all(["status =?", BatchStatus::OUTPUT_GENERATING], "id in (#{all_batch_ids.join(",")})") 
      cgf = CheckGroupFile.new(batches_for_output.first.facility)
      cgf.send :process_batch_ids, batch_ids, batch_ids_for_supplemental_output
      Batch.update_all(["status =?", BatchStatus::OUTPUT_GENERATED], "id in (#{all_batch_ids.join(",")})") 
      #OperationLog::Generator.new(batch.id).generate
      OtherOutput::Automator.new(batch.id, batch_ids).process
      t = Time.now
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end

  task :generate_rapack, [:batch_id] => :environment do |t, args|
    batch = Batch.find(args.batch_id)
    if batch.qualified_for_output_generation?
      batches_for_output = batch.batch_bundle
      batches_for_output.map{|b| b.update_attribute(:output_835_start_time, Time.now)}
      #batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      puts "Collecting the Batch ids for the 835s................"
      batch_ids = OutputBatch.new.get_batchid(args.batch_id)
      puts "The Batch ids for the 835s are #{batch_ids}"
      if batch_ids
        OtherOutput::RaGenerator.new(batch.id, batch_ids).process
      else
        puts "something gone wrong in batch id collection of 835s......"
      end
    else
      puts "Batch #{batch.batchid} is not ready for output generation, please check the status"
    end
  end

end
