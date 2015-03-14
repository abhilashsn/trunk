# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class SiteSetting < ActiveRecord::Base
  validates_presence_of :per_page
  validates_numericality_of :per_page
end
