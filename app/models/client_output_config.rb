class ClientOutputConfig < ActiveRecord::Base
  belongs_to :client
  serialize :operation_log_config

  # Fetches the Operation Log configuration record/s for a client id
  scope :operation_log,
    lambda{ |client_id| { :conditions => {:report_type => "Operation Log",
        :client_id => client_id}}}

  def grouping_weight
    case operation_log_config[:group_by]["0"]
    when 'client and deposit date'
      4
    when 'nextgen'
      3
    when 'batch date'
      2
    when 'batch'
      1
    else
      0
    end
  end
end
