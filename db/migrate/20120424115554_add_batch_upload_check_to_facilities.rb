class AddBatchUploadCheckToFacilities < ActiveRecord::Migration
  def change
    ## Adding a boolean flag
    add_column :facilities, :batch_upload_check, :boolean ,:default=>false

    ## Updating the boolean flag with existing Facilty name
#    facilities = ["SOUTH COAST","ORTHOPAEDIC FOOT AND ANKLE CTR","CHATHAM HOSPITALISTS",
#      "SAVANNAH SURGICAL ONCOLOGY","SAVANNAH PRIMARY CARE","GEORGIA EAR ASSOCIATES",
#      "ADVANCED SURGEONS PC","HAYDEN VISION LLC","VISALIA MEDICAL CLINIC",
#      "SHEPHERD EYE CENTER","SHEPHERD EYE SURGICENTER","Coug","Glacier","ELIXAIR MEDICAL INC",
#      "ALBERT EINSTEIN COLLEGE OF MEDICINE","SUBURBAN ORTHO & MEDICAL CENTER LLC",
#      "Anthem","UWL","DOWNEY REGIONAL MEDICAL CENTER","Merit Mountainside"
#    ]
#
#    facilities.each do |item|
#      Facility.all.each do |f|
#        if f.name == item
#          f.update_attribute(:batch_upload_check , true)
#        end
#      end
#    end
    
  end
end
