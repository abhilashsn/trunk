class OperationLogCsv::GoodmanCampbellCheck < OperationLogCsv::Check
  
  def reject_reason
    if operation_log_config.details[:reject_reason]
      eob = InsurancePaymentEob.find(:first,
        :conditions => ['check_information_id = ?', check.id])
     (eob.blank? || eob.rejection_comment.blank?) ? "-" : eob.rejection_comment
    end
  end

end 