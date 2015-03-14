# == Schema Information
# Schema version: 69
#
# Table name: client_status_histories
#
#  id       :integer(11)   not null, primary key
#  batch_id :integer(11)
#  time     :datetime
#  status   :string(255)
#  user     :string(255)
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class ClientStatusHistory < ActiveRecord::Base
  belongs_to :batch
end
