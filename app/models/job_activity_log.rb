class JobActivityLog < ActiveRecord::Base
	belongs_to :job
	belongs_to :processor, :class_name => "User", :foreign_key => "processor_id"
	belongs_to :qa, :class_name => "User", :foreign_key => "qa_id"
	belongs_to :allocated_user, :class_name => "User", :foreign_key => "allocated_user_id"

  cattr_accessor :current_user_id, :associated_job_id
  @@current_user_id, @@associated_job_id = nil, nil

  def self.create_activity(parameters = {}, to_save = true)
    activity = self.new({
        :job_id => parameters[:job_id],
        :processor_id => parameters[:processor_id],
        :qa_id => parameters[:qa_id],
        :allocated_user_id => parameters[:allocated_user_id],
        :activity => parameters[:activity],
        :start_time => parameters[:start_time],
        :end_time => parameters[:end_time],
        :eob_id => parameters[:eob_id],
        :eob_type_id => parameters[:eob_type_id],
        :object_name => parameters[:object_name],
        :object_id => parameters[:object_id],
        :field_name => parameters[:field_name],
        :old_value => parameters[:old_value],
        :new_value => parameters[:new_value]
      })
    if to_save
      activity.save
    else
      activity
    end
  end

  def self.record_changed_values(object)
    if @@current_user_id && object.id.present? && object.changed?
      activities = []
      object.changed_attributes.each do |attribute, value|

        if !['created_at', 'updated_at', 'details'].include?(attribute)
          changed_values = object.send("#{attribute}_change")
          old_value = changed_values[0]
          new_value = changed_values[1]
          if old_value.present? && old_value != new_value

            attributes = {:allocated_user_id => @@current_user_id,
              :activity => "#{object.class} change", :start_time => Time.now,
              :object_name => "#{object.class.table_name}", :object_id => object.id,
              :field_name => attribute.to_s, :old_value => old_value, :new_value => new_value}
            attributes[:job_id] = @@associated_job_id if @@associated_job_id
            
            activities << self.create_activity(attributes, false)
          end
        end
      end
      self.import activities if !activities.blank?
    end
    
  end

end
