# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class EobError < ActiveRecord::Base
  validates_presence_of :error_type, :severity
  def to_s
    self.error_type
  end
end
