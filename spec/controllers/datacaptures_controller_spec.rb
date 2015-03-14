require 'spec_helper'
require 'devise/test_helpers' 


describe DatacapturesController do
  
  before(:each) do
    sign_in FactoryGirl.create(:a_proc_user)
  end
  
    
    # subject { controller.save_primary_reason_code_ids("coinsurance",2) }
    it "should" do
      # ipe_stub = FactoryGirl.stub(:a_patpay)
      # ipe_stub = build_stubbed(FactoryGirl.create(:a_patpay))
      # InsurancePaymentEob.stub!(:to_s).and_return(nil)
      # String.stub!(:underscore)
      get :insurance_eob_save, {"insurancepaymenteob"=>FactoryGirl.create(:a_patpay).attributes }
      puts "***********\n#{MpiStatisticsReport.includes(:batch).where("batches.lockbox = 10312013").count}\n*********"
      
      expect(MpiStatisticsReport.includes(:batch).where("batches.lockbox = 10312013").count).to be > 0
      
    end
    
    before{controller.instance_variable_set(:@entity, InsurancePaymentEob.first)}
    it "should build the entity based on reason code for coinsurance" do
      controller.build_reason_or_hipaa_code_ids("coinsurance","reason_code_id",2)
      expect(controller.instance_variable_get(:@entity).coinsurance_reason_code_id).to eq(2) 
    end
     it "should build the entity based on reason code for miscellaneous_two" do
      controller.build_reason_or_hipaa_code_ids("miscellaneous_two","reason_code_id",3)
      expect(controller.instance_variable_get(:@entity).miscellaneous_two_reason_code_id).to eq(3) 
    end  
    it "should build the entity based on reason code for contractual" do
      controller.build_reason_or_hipaa_code_ids("contractual","hipaa_code_id",4)
      expect(controller.instance_variable_get(:@entity).contractual_hipaa_code_id).to eq(4) 
    end 
    it "should build the entity based on reason code for noncovered" do
      controller.build_reason_or_hipaa_code_ids("noncovered","hipaa_code_id",5)
      expect(controller.instance_variable_get(:@entity).noncovered_hipaa_code_id).to eq(5) 
    end    
end