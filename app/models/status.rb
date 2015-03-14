# == Schema Information
# Schema version: 69
#
# Table name: statuses
#
#  id    :integer(11)   not null, primary key
#  value :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Status 
  NEW = "New"
  PROCESSING = "Processing"
  COMPLETE = "Completed"
end
