module OperationLog
  module AdvancedSurgeonsPcCheck
    def eval_batch_name
        check.batch.batchid.blank? ? "-" : check.batch.batchid.split("_").first
    end
  end
end
