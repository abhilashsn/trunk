class ChangeValueFromLockboxcutToCutInFacilityLookupFields < ActiveRecord::Migration
  def up
    execute "UPDATE facility_lookup_fields SET NAME='By Cut' WHERE NAME='By LockBox Cut'"
  end

  def down
    execute "UPDATE facility_lookup_fields SET NAME='By LockBox Cut' WHERE NAME='By Cut'"
  end
end
