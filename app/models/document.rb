# == Schema Information
# Schema version: 69
#
# Table name: documents
#
#  id        :integer(11)   not null, primary key
#  filename  :string(255)   
#  content   :binary        
#  file_type :string(255)   
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Document < ActiveRecord::Base
  belongs_to :client
  validates_uniqueness_of :filename
  
  def full_path
    path = "/tmp/#{self.filename}"
  end
  
  # Selects all columns but content. This prevents returning BLOB data when not needed.
  # Takes most of the same options as ActiveRecord#find
  #
  # TODO: Currently doesn't work with :include
  
  def self.find_without_content(*args)
    select_columns = self.columns.map {|c| c.name}.select {|n| n != 'content'}.join(", ")

    if args.last.is_a?(Hash) then
      args.last.merge!(:select => select_columns)
    else
      args << {:select => select_columns}
    end
    
    self.find(*args)
  end
end
