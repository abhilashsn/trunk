namespace :reason_code_revamp do
  desc "set defualt reason_code_set_name for payers"
  task :reason_code_setname_for_payers => [:environment] do |t,args|   
    Payer.find_in_batches(:conditions=>"reason_code_set_name_id is null") do |group|
      group.each do |payer|
        payer.reason_code_set_name = ReasonCodeSetName.find_or_create_by_name("DEFAULT_#{payer.id}")
        payer.save
      end
    end
  end

  desc "Migrates the reason codes data from CIT3 to CIT4 DB"
  task :migrate_from_cit3 => :environment do
    multiple_payer_rcs = ReasonCode.all(:select => "reason_codes.*, reason_codes_payers.*, count(reason_code_id) as count",
      :joins => :reason_codes_payers, :group => "reason_code_id")
      success &&= true
    multiple_payer_rcs.each do |mrc|
      if mrc.count.to_i > 1
        (mrc.count.to_i - 1).times do
          rc_set_name_id = Payer.first(mrc.payer_id).reason_code_set_name_id
          rc = ReasonCode.new(:reason_code => mrc.reason_code, :reason_code_description => mrc.reason_code_description, :status => mrc.status,
            :check_information_id => mrc.check_information_id, 
            :reason_code_set_name_id => rc_set_name_id, :created_at => mrc.created_at,
            :updated_at => mrc.updated_at)
          success &&= rc.save
        end
      end
      mrc.status = mrc.status
      mrc.reason_code_set_name_id = Payer.first(mrc.payer_id).reason_code_set_name_id
      success &&= mrc.save
    end

    if success
      success &&= ReasonCodesPayers.delete_all
    end

    rcs_without_set_names = ReasonCodes.all(:reason_code_set_name_id => nil)
    if rcs_without_set_names.count > 0
      set_name = ReasonCodeSetNames.new(:name => 'DEFAULT_RC_SET')
      if set_name.save
        rcs_without_set_names.each do |rc|
          rc.reason_code_set_name_id = set_name.id
          success &&= rc.save
        end
      end
    end

    if success
      "The Reason Code related data has been successfully migrated from CIT3 data model to that of CIT4"
    end

  end
end
