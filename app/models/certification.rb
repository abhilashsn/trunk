# == Schema Information
# Schema version: 69
#
# Table name: certifications
#
#  id        :integer(11)   not null, primary key
#  user_id   :integer(11)   
#  client_id :integer(11)   
#  date      :date          
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Certification < ActiveRecord::Base
  belongs_to :user
  belongs_to :client
end
