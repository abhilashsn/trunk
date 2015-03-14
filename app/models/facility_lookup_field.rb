class FacilityLookupField < ActiveRecord::Base
  validates_presence_of :name
  scope :by_835, :conditions => "lookup_type like '835_SEG%'", :order=>'sort_order'
  scope :segment_835, :conditions=> "lookup_type = '835_SEG'",:group=>:sub_category
  scope :operation_log, :conditions=> "lookup_type = 'operation_log'"
  scope :other_outputs, :conditions=> "lookup_type = 'other_output'"
  scope :tat_comments, :conditions => "lookup_type = 'TAT Comment'", :order => 'name ASC'
end
