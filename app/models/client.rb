# == Schema Information
# Schema version: 69
#
# Table name: clients
#
#  id             :integer(11)   not null, primary key
#  name           :string(255)   
#  tat            :integer(11)   
#  contracted_tat :integer(11)   default(20)
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Client < ActiveRecord::Base
  has_many :facilities, :dependent => :destroy
  has_many :client_output_configs, :dependent => :destroy
  has_many :documents
  has_many :batches
  has_many :error_popups, :dependent => :destroy
  has_many :inbound_file_informations
  has_many :config_settings
  validates_presence_of :name, :message=> " is mandatory"
  validates_uniqueness_of :name,:message=> " should be unique",:case_sensitive => false 
  validates :tat, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,:message=> " mandatory and should be numeric" }
  validates :partener_bank_group_code, :presence => true
  validates :internal_tat, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,:message=> "mandatory and should be numeric" }
  validates_presence_of :group_code,:message => " is mandatory"
  validates_uniqueness_of :group_code,:message => " should be unique"
  validates :max_eobs_per_job, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,:message=> "mandatory and should be numeric" }
  validates :max_jobs_per_user_client_wise, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0,:message=> "mandatory and should be numeric" }
  validates :max_jobs_per_user_payer_wise, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 ,:message=> "mandatory and should be numeric"}
  belongs_to :partner
  serialize :custom_fields, Hash

  
  # Methods for 835 Output Generation #

  def client_name
    self.name.strip.upcase
  end

  def trn_03_exception_clients
    ["NAVICURE", "ASCEND CLINICAL LLC"].include? (client_name)
  end

  def is_orbo_client?
    Client.orbograph?(client_name)
  end
  # End of 835 Output Generation Methods #

  # needs to be a Class method, cannot be called for an instance, hence duplicated.
  def self.is_client_orbograph?(name_of_client)
    Client.orbograph?(name_of_client.to_s.upcase)
  end

  def self.orbograph?(name_of_client)
    ['ORBOGRAPH', 'ORB TEST FACILITY'].include? (name_of_client)
  end
  
end
