class OperationLogCsv::AdvancedSurgeonsPcCheck < OperationLogCsv::NavicureCheck

def batch_name
  if operation_log_config.details[:batch_name]
    check.batch.batchid.blank? ? "-" : check.batch.batchid.split("_").first
  end
end

end