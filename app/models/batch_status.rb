# == Schema Information
# Schema version: 69
#
# Table name: batch_statuses
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class BatchStatus < ActiveRecord::Base
  NEW = "NEW"
  PROCESSING = "PROCESSING"
  COMPLETED = "COMPLETED"
  OUTPUT_READY = "OUTPUT_READY"
  OUTPUT_GENERATING = "OUTPUT_GENERATING"
  OUTPUT_GENERATED = "OUTPUT_GENERATED"  
  OUTPUT_EXCEPTION = "OUTPUT_EXCEPTION"
  ARCHIVED = "ARCHIVED"
  DEALLOCATED = "DEALLOCATED" #"Remove From Allocation"
  LOADING = "LOADING"
end
