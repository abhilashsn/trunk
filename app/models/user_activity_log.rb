######## UserActivityLog API ##########
# Author : Neethu Satheesh
#
# UserActivityLog allows you to log the actions of a user performed in RevRemit 
# and helps you to trouble shoot with this information.
# This API has to be used in the areas of RevRemit where data modification is crucial for its normal functioning.
# Or where we can track the user activity.
# This will store what kind of an 'action' 'user' performed on an 'object' and 'when'.
# Eg : 
# 1) I logged in, ie current user logged in at 02/06/2012, 11.00
#    Here, user => current user, role => role of current user,
#           activity => 'Logged in', performed_at => '02/06/2012, 11.00'
# 2) I updated an 'EOB object' at 02/06/2012, 11.00
#    Here, user => current user, role => role of current user,
#      activity => 'Updated EOB', :entity_name => 'InsurancePaymentEOB',
#      entity_id => PK of 'EOB object', performed_at => '02/06/2012, 11.00'
# Additional information can be logged in the attribute 'description'

# Methods : create_activity_log, search_all_by
# Updation & deletion of an object of UserActivityLog is restricted, for simple reason that,
#  whatever you had logged can't be reverted.
# 
# To create an object of UserActivityLog use:
#  UserActivityLog.create_activity_log(user, activity, entity_object, description)
# To search for logs use :
#  UserActivityLog.search_all_by(parameter_name, parameter)

class UserActivityLog < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :activity, :user_id
 
  # create_activity_log creates an object of UserActivityLog
  # Input :
  # user : current user
  # activity : action performed by the user, sometimes may be on the entity_object
  #  Eg : Logged in, Logged out, Created the batch, Deleted the batch, Updated the user
  # entity_object : the object which the user has worked on 
  #  Eg : object of Batch, InsurancePaymentEOB, User etc
  # description : Additional description 
  #  Eg : modified the user's role, deleted the faulty batch, deleted the faulty EOB
  def self.create_activity_log(user, activity, entity_object = nil, description = nil,ip_address = nil)
    if !user.blank?
      user_id = user.id
      role_of_user = user.roles.first.name
    end
    if !entity_object.blank?
      entity_name = entity_object.class.to_s.upcase
      entity_id = entity_object.id
    end
    activity_log = self.new(:user_id => user_id, :role => role_of_user, 
      :activity => activity, :performed_at => Time.now,
      :description => description, :entity_name => entity_name, :ip_address => ip_address,
      :entity_id => entity_id)
    if activity_log.valid?
      activity_log.save
    else
      logger.error "Creation of UserActivityLog has failed : #{activity_log.errors.full_messages}"
    end
  end
  
  # Allows you to find the records matching the given parameters
  # This contains only primitive logic. As the need increases please expand.
  # Input :
  # parameter_name : Name of the attribute for which you are searching for.
  # parameter : the attribute to search for.
  # Eg : parameter_name : parameter
  # 'USER' : login of user object
  # 'ACTIVITY' : 'Logged in', Batch created, TAT Comments created
  # 'ENTITY' : class name of the object, Batch, InsurancePaymentEob
  def self.search_all_by(parameter_name, parameter)
    if !parameter.blank? && !parameter_name.blank?
      case parameter_name.to_s.upcase
      when 'USER'
        condition = "user_id = ?"
        user = User.find_by_login(parameter)
        search_parameter = user.id if user
      when 'ACTIVITY'
        condition = "activity like ?"
        search_parameter = "%#{parameter}%"
      when 'ENTITY'
        condition = "entity_name = ?"
        search_parameter = parameter
      end
      if !condition.blank? && !search_parameter.blank?
        self.where([condition, search_parameter])
      end
    end
  end
  
  
end
