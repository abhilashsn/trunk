# == Schema Information
# Schema version: 69
#
# Table name: processor_statuses
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class ProcessorStatus
  NEW = "NEW"
  ALLOCATED = "ALLOCATED"
  COMPLETED = "COMPLETED"
  INCOMPLETED = "INCOMPLETED"
  ADDITIONAL_JOB_REQUESTED = "ADDITIONAL_JOB_REQUESTED"
end
