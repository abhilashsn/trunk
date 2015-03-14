# == Schema Information
# Schema version: 69
#
# Table name: sampling_rates
#
#  id    :integer(11)   not null, primary key
#  slab  :string(255)   
#  value :integer(11)   default(5)
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class SamplingRate < ActiveRecord::Base
end
