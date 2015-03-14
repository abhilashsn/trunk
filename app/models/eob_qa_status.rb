# == Schema Information
# Schema version: 69
#
# Table name: eob_qa_statuses
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class EobQaStatus
  ACCEPTED = "Accepted"
	REJECTED = "Rejected"
end
