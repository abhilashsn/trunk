# == Schema Information
# Schema version: 69
#
# Table name: job_statuses
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class JobStatus
  #  REJECTED    = "QA Rejected"
  #  ALLOCATED   = "Processor Allocated"
  NEW = "NEW"
  PROCESSING = "PROCESSING"
  COMPLETED = "COMPLETED"
  INCOMPLETED = "INCOMPLETED"
  EXCLUDED = "EXCLUDED"
  REJECTED = "REJECTED"
  OCR = "OCR"
  ADDITIONAL_JOB_REQUESTED = "ADDITIONAL_JOB_REQUESTED"


  OCR_PROCESSING = "PROCESSING"
  OCR_SUCCESS = "SUCCESS"
  OCR_EXCEPTION = "EXCEPTION"
  OCR_ARRIVED = "ARRIVED"  
  OCR_LATE = "LATE"  
  OCR_FAILED = "FAILED"
end
