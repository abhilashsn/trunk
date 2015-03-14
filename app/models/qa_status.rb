# == Schema Information
# Schema version: 69
#
# Table name: qa_statuses
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class QaStatus
  NEW = "NEW"
  ALLOCATED = "ALLOCATED"
  PROCESSING = "PROCESSING"
  COMPLETED = "COMPLETED"
  INCOMPLETED = "INCOMPLETED"
  REJECTED = "REJECTED"
end
