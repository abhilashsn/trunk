# == Schema Information
# Schema version: 69
#
# Table name: eobrates
#
#  id        :integer(11)   not null, primary key
#  high      :integer(11)   
#  medium    :integer(11)   
#  low       :integer(11)   
#  client_id :integer(11)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Eobrate < ActiveRecord::Base
  belongs_to :client
end
