class RolesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  
  #23792
  #below code will replace role_user.role.name to role_user.role_name
  delegate :name, :to => :role, :prefix => true, :allow_nil => true
  
  # Use User.has_role? method instead of this method
  # def self.is_role(userid)
  #  role = RolesUser.find_by_user_id(userid).role_id
  #  user_role = Role.find(role).name
  #  return user_role
  # end
  
end
