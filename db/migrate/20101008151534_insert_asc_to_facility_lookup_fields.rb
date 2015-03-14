class InsertAscToFacilityLookupFields < ActiveRecord::Migration
  def up
    asc = FacilityLookupField.find(:all, :conditions => {:name => 'ASC', :lookup_type => 'Index File Format'})
    if asc.blank?
      FacilityLookupField.create(:name => 'ASC', :lookup_type => 'Index File Format')
    end
  end

  def down
    FacilityLookupField.delete(:all, :conditions => {:name => 'ASC', :lookup_type => 'Index File Format'})
  end
end
