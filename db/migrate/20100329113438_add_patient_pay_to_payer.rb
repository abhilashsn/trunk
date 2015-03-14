class AddPatientPayToPayer < ActiveRecord::Migration
  def up
    #  Creating a predefined payer "PATIENT PAY" for Merit Mountainside patpay output.
    mountainside = Facility.find(:first, :conditions => ["name =?" ,"Merit Mountainside"], :select => "name name, address_one address_one, address_two address_two, city city, state state, zip_code zip_code")
    if mountainside
      Payer.create(:payer => "PATIENT PAY", :payid => "P9998", :gateway => "client", :payer_type => "PatPay",
      :pay_address_one => mountainside.address_one, :pay_address_two => mountainside.address_two, :payer_zip => mountainside.zip_code, :payer_state => mountainside.state, :payer_city => mountainside.city, :details => nil)
      puts "Created the predefined payer 'PATIENT PAY' for Merit Mountainside patpay output."
    end    
  end

  def down
  end
end
