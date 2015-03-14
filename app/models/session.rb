# == Schema Information
# Schema version: 69
#
# Table name: sessions
#
#  id         :integer(11)   not null, primary key
#  session_id :string(255)   
#  data       :text          
#  updated_at :datetime      
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Session < ActiveRecord::Base
end
