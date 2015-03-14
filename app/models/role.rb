class Role < ActiveRecord::Base
  has_many :users, :through => :roles_users
  has_many :roles_users
    
  def to_s
    self.name
  end
  
  def self.[](key)
    self.find_by_name(key)
  end
  
  
end