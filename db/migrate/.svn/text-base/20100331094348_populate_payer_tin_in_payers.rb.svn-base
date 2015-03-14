class PopulatePayerTinInPayers < ActiveRecord::Migration
  #  Ppopulating the default Payer TIN.
  
  def up
    # 'facility_with_tin' stores the facility name and the tin to be populated as its payer's TIN
    facility_with_tin = {
      "Richmond University Medical Center" => "999999999",
      "Merit Mountainside" => "999999999",
      "PEMA" => "999999999",
      "INTERNAL MEDICINE SPECIALISTS" => "999999999",
      "SOUTH COAST" => "000000009",
      "GEORGIA EAR ASSOCIATES" => "000000009",
      "CHATHAM HOSPITALISTS" => "000000009",
      "ORTHOPAEDIC FOOT AND ANKLE CTR" => "000000009",
      "SAVANNAH SURGICAL ONCOLOGY" => "000000009",
      "SAVANNAH PRIMARY CARE" => "000000009",
      "CLINIX HEALTH SERVICES OF CO INC" => "000000009",
      "HORIZON EYE" => "000000009",
      "OKLAHOMA CARDIOVASCULAR ASSOC" => "000000009",
      "LINCOLN HOSP DISTRICT 3" => "000000009",
      "UROLOGY SPEC OF NV" => "000000009",
      "UROLOGY ASSOC OF CENTRAL CALIFORNIA" => "000000009",
      "UROLOGY SPEC PEDIATRIC" => "000000009",
      "SHEPHERD VSP" => "999999999",
      "AHN" => "000000009",
      "KINEMATIC CONCEPTS PHYSICAL THERAPY AND SPORTS REHAB" => "999999999",
      "New Braunfels Sports and Spine Physical Therapy" => "999999999"
    }

    facility_with_tin.each do |facility_name, payer_tin|
      facility = Facility.find(:first, :conditions => ["name=?", facility_name], :select => "name")
      if facility
        payers = Payer.find(:all, :conditions => ["gateway =? ",facility.name])
        payers.each do |payer|
          payer.payer_tin = payer_tin
          payer.save!
        end
      end
   end  
 end


  def down
  end
end
