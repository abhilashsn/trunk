# == Schema Information
# Schema version: 69
#
# Table name: job_rejection_comments
#
#  id      :integer(11)   not null, primary key
#  comment :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class JobRejectionComment < ActiveRecord::Base
  def to_s
    self.comment
  end
end
