class ChangeStateOfMountainside < ActiveRecord::Migration
  def up
      mountain_side = Facility.find_by_name("Merit Mountainside")
      if(!mountain_side.nil? or !mountain_side.blank?)  
        mountain_side.state = "NJ"
        mountain_side.save!
      end
      
  end

  def down
  end
end
