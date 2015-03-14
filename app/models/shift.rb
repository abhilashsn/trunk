# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Shift < ActiveRecord::Base
  has_many :users
end
