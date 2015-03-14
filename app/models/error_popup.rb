class ErrorPopup < ActiveRecord::Base
  validates_presence_of :comment

  belongs_to :facility
  belongs_to :client
  belongs_to :reason_code_set_name
  belongs_to :processor, :class_name => "User", :foreign_key => :processor_id
  belongs_to :data_file

  def self.get_all_alerts(batch, user_id, rc_set_name_id)
    alerts = self.find(:all,
      :conditions => ["(processor_id is null or processor_id = ?)
       and (facility_id is null or facility_id = ?)
       and (reason_code_set_name_id is null or reason_code_set_name_id = ? )
       and client_id = ? and start_date <= ? and end_date > ?
       and field_id is not null and field_id != ''",
        "#{user_id}", "#{batch.facility_id}", "#{rc_set_name_id}", "#{batch.client_id}",
        "#{(Time.now).strftime("%y/%m/%d")}", "#{Time.now.strftime("%y/%m/%d")}"])
    
    alert_ids = alerts.collect{|alert| alert.id}.join('--')
    alert_fields = alerts.collect{|alert| alert.field_id.strip}.join('-')
    alert_qns = alerts.collect{|alert| alert.Question.strip}.join('-')
    alert_comments = alerts.collect{|alert| alert.comment.strip}.join('-')
    alert_id_with_questions = alerts.collect{|alert| alert.id if (alert.Question != '')}.join('-')
    return alert_ids, alert_fields, alert_qns, alert_id_with_questions,alert_comments
  end

  
end
