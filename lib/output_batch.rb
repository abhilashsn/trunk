# To change this template, choose Tools | Templates
# and open the template in the editor.

class OutputBatch
  
  def get_batchid(batchid)
    batch = Batch.find(batchid)
    if FacilityOutputConfig.insurance_eob(batch.facility.id) &&
        FacilityOutputConfig.insurance_eob(batch.facility.id).length > 0
      @insurance_eob_output_config = FacilityOutputConfig.insurance_eob(batch.facility.id).first
      output_grouping = @insurance_eob_output_config.grouping.upcase
    end
    groupings = ["SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
    if groupings.include?(output_grouping)
      if output_grouping == "SINGLE DAILY MERGED CUT"
        batches = Batch.find(:all,:conditions => {:date => batch.date, :facility_id => batch.facility_id, :status => BatchStatus::OUTPUT_READY})
      end
      if output_grouping == "SEQUENCE CUT"
        batches = Batch.find(:all,:conditions => {:date => batch.date,:cut=>batch.cut, :facility_id => batch.facility_id, :status => BatchStatus::OUTPUT_READY})
      end
      batch_ids = batches.collect(&:id)
    else
      if batch.qualified_for_output_generation?
        batches_for_output = batch.batch_bundle
        batches_for_output.delete_if{|b| b.correspondence.nil? && b.index_batch_number == "0"}
        batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      end
    end
    if batch_ids
      return batch_ids
    else
      puts "No Batch is qualified for output generation"
    end
  end
end
