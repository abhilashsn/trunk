# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddDefaultEobErrors < ActiveRecord::Migration
  def up
    error_list = [
      {:severity => 0, :error_type => "Correct", :code => "COR"},
      #{:severity => 9, :error_type => "Health Insurance Coverage Wrong Selection", :code => "HCW"},
      #{:severity => 9, :error_type => "Health Insurance Coverage Unchecked", :code => "HCU"},
      {:severity => 9, :error_type => "Payee Name - Missing", :code => "III"},
      {:severity => 8, :error_type => "Payee Name - Incorrect", :code => "PNS"},
      {:severity => 7, :error_type => "Payee NPI - Missing", :code => "PNI"},
      {:severity => 7, :error_type => "Payee NPI - Incorrect", :code => "PMM"},
      {:severity => 7, :error_type => "Payee TIN - Incorrect", :code => "PSM / PSI"},
      {:severity => 7, :error_type => "Payee TIN - Missing", :code => "PDI"},
      {:severity => 7, :error_type => "Payer Name - Wrong selection", :code => "PGW"},
      {:severity => 7, :error_type => "Payer Address - Incorrect", :code => "INS"},
      {:severity => 5, :error_type => "Payer City - Incorrect", :code => "INI"},
      {:severity => 5, :error_type => "Payer City - Missing", :code => "IMI"},
      {:severity => 8, :error_type => "Payer State - Incorrect", :code => "ISM / ISI"},
      {:severity => 8, :error_type => "Payer State - Missing", :code => "CYI"},
      {:severity => 7, :error_type => "Payer Zip code - Incorrect", :code => "CHL"},
      {:severity => 7, :error_type => "Payer Zip code - Missing", :code => "STW"},
      {:severity => 5, :error_type => "Payer TIN - Incorrect", :code => "ZPI"},
      {:severity => 5, :error_type => "Payer TIN - Missing", :code => "PHI"},
      {:severity => 7, :error_type => "Patient Name  Shuffled ", :code => "PRI"},
      {:severity => 7, :error_type => "Middle Name Missing", :code => "PSW"},
      #{:severity => 5, :error_type => "Other Insured\'s Name First/Last name shuffle", :code => "ONS"},
      #{:severity => 5, :error_type => "Other Insured\'s Name Incorrect", :code => "ONI"},
      #{:severity => 5, :error_type => "Other Insured\'s Name Middle Initial Missing", :code => "OMM"},
      #{:severity => 10, :error_type => "Other Insured\'s Name Suffix Missing/Incorrect", :code => "OSM/OSI"},
      #{:severity => 7, :error_type => "Other Insured\'s Policy Number Incorrect", :code => "OPI"},
      #{:severity => 7, :error_type => "Other Insured\'s DOB Incorrect", :code => "ODI"},
      #{:severity => 10, :error_type => "Other Insured\'s Gender Wrong Selection", :code => "OGW"},
      #{:severity => 10, :error_type => "Employers' Name Missing", :code => "MUL"},
      #{:severity => 8, :error_type => "Employers' Name Incorrect", :code => "ENI"},
      {:severity => 8, :error_type => "Middle Name Incorrect", :code => "IPM"},
      {:severity => 8, :error_type => "First/Last Name Incorrect", :code => "IPI"},
      {:severity => 8, :error_type => "Patient Name -Suffix Missing", :code => "PCW"},
      # MOVED {:severity => 8, :error_type => "Patient\'s Name - Suffix Incorrect", :code => "AAI"},
      #{:severity => 7, :error_type => "Reserved For Local Use Missing", :code => "LUM"},
      #{:severity => 7, :error_type => "Reserved For Local Use Incorrect", :code => "LUI"},
      {:severity => 8, :error_type => "Patient Account Number - Incorrect", :code => "IGM"},
      {:severity => 8, :error_type => "Claim Number - Missing", :code => "IGI"},
      {:severity => 8, :error_type => "Claim Number - Incorrect", :code => "IDI"},
      {:severity => 7, :error_type => "Qualifier - Wrong Selection", :code => "IGW"},
      {:severity => 5, :error_type => "Patient Identification Qualifier - Missing", :code => "SGW"},
      {:severity => 8, :error_type => "Patient Identification Qualifier - Incorrect", :code => "DSI"},
      #{:severity => 7, :error_type => "Date of Signature Missing", :code => "DSM"},
      {:severity => 7, :error_type => "Member Id - Missing", :code => "DCI"},
      {:severity => 5, :error_type => "Member Id - Incorrect", :code => "DCM"},
      {:severity => 5, :error_type => "Interest Missing", :code => "SDI"},
      {:severity => 8, :error_type => "Interest Incorrect", :code => "PUI"},
      {:severity => 8, :error_type => "Subscirber Name - Incorrect", :code => "PUM"},
      {:severity => 7, :error_type => "Subscirber Name - Shuffled", :code => "RPI"},
      # MOVED {:severity => 8, :error_type => "Subscirber\'s Middle Name - Missing", :code => "RPM"},
      # MOVED {:severity => 8, :error_type => "Subscirber\'s Middle Name - Incorrect", :code => "NNI"},
      # MOVED {:severity => 8, :error_type => "Subscriber\'s suffix - Missing", :code => "NNI"},
      # MOVED {:severity => 6, :error_type => "Subscriber\'s suffix - Incorrect", :code => "NPI"},
      {:severity => 6, :error_type => "Claim Type - Wrong Selection", :code => "NPM"},
      {:severity => 5, :error_type => "Provider Name -Shuffled", :code => "HDI"},
      # MOVED {:severity => 5, :error_type => "Provider\'s Middle Name Missing", :code => "HDM"},
      #{:severity => 10, :error_type => "Outside Lab  Wrong Selection", :code => "OLW"},
      #{:severity => 10, :error_type => "Outside Lab Charge Incorrect", :code => "LCI"},
      #{:severity => 6, :error_type => "Outside Lab Charge Missing", :code => "LCM"},
      # MOVED {:severity => 6, :error_type => "Provider\'s Middle Name Incorrect", :code => "DGI"},
      # MOVED {:severity => 5, :error_type => "Provider\'s Suffix Incorrect", :code => "DGM"},
      #{:severity => 5, :error_type => "Medicaid Resubmission Code Incorrect", :code => "MCI"},
      #{:severity => 10, :error_type => "Medicaid Resubmission Code Missing", :code => "MCM"},
      #{:severity => 10, :error_type => "Original Reference No Missing", :code => "ORM"},
      #{:severity => 6, :error_type => "Original Reference No Incorrect", :code => "ORI"},
      # MOVED {:severity => 5, :error_type => "Provider\'s Suffix Missing", :code => "ANI"},
      {:severity => 5, :error_type => "Provider NPI - Missing", :code => "ANM"},
      {:severity => 10, :error_type => "Provider NPI - Incorrect", :code => "DTI"},
      {:severity => 10, :error_type => "Provider TIN - Missing", :code => "PLI"},
      {:severity => 5, :error_type => "Provider TIN - Incorrect", :code => "EMI"},
      {:severity => 5, :error_type => "Plan Type - Wrong Selection", :code => "EMM"},
      {:severity => 10, :error_type => "Date of Service From /To  - Missing", :code => "CPI"},
      {:severity => 10, :error_type => "Date of Service From / To- Incorrect", :code => "MOI"},
      {:severity => 5, :error_type => "Procedure Code - Missing", :code => "MOM"},
      {:severity => 5, :error_type => "Procedure Code - Incorrect", :code => "DPI"},
      {:severity => 10, :error_type => "Modifier - Missing", :code => "CHI"},
      {:severity => 10, :error_type => "Modifier - Incorrect", :code => "UTM"},
      {:severity => 5, :error_type => "Units - Missing", :code => "UTI"},
      {:severity => 5, :error_type => "Units - Incorrect", :code => "EPM"},
      {:severity => 0, :error_type => "Charges - Missing", :code => "EPI"},
      {:severity => 9, :error_type => "Charges - Incorrect", :code => "IQI"},
      {:severity => 9, :error_type => "Non-Covered - Missing", :code => "IQM"},
      {:severity => 9, :error_type => "Non-Covered - Incorrect", :code => "TDI"},
      {:severity => 8, :error_type => "Discount - Missing", :code => "TDW"},
      {:severity => 7, :error_type => "Discount - Incorrect", :code => "PAI"},
      {:severity => 7, :error_type => "Allowable Amount - Missing", :code => "AAW"},
      {:severity => 7, :error_type => "Allowable Amount - Incorrect", :code => "API"},
      {:severity => 7, :error_type => "Contactual Allowance - Incorrect", :code => "SSW"},
      {:severity => 7, :error_type => "Coinsurance - Missing", :code => "SNS"},
      {:severity => 7, :error_type => "Coinsurance - Incorrect", :code => "SNI"},
      {:severity => 5, :error_type => "Deductible - Missing", :code => "SMM"},
      {:severity => 5, :error_type => "Deductible - Incorrect", :code => "SSM"},
      {:severity => 8, :error_type => "Copay - Missing", :code => "OZI"},
      {:severity => 8, :error_type => "Copay - Incorrect", :code => "BNS"},
      {:severity => 7, :error_type => "Payment - Missing", :code => "BNI"},
      {:severity => 7, :error_type => "Payment - Incorrect", :code => "BMM"},
      {:severity => 5, :error_type => "PPP Amount - Missing", :code => "BSM"},
        {:severity => 5, :error_type => "PPP Amount - Incorrect", :code => "MCI"},
      {:severity => 10, :error_type => "Unprocessed EOB", :code => "MCM"},
      {:severity => 10, :error_type => "Duplication of EOB", :code => "ORM"},
      {:severity => 6, :error_type => "Service Line - Unbalanced", :code => "ORI"},
       {:severity => 10, :error_type => "Reason Code - Incorrect", :code => "ORM"},
      {:severity => 6, :error_type => "Reason Code Description - Incorrect", :code => "ORI"},
      
    ]
    error_list.each do |e|
      execute "INSERT INTO eob_errors(severity,error_type,code) VALUES(#{e[:severity]}, '#{e[:error_type]}', '#{e[:code]}')"
    end

      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(8, "Patient\'s Name - Suffix Incorrect", "AAI")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(8, "Subscirber\'s Middle Name - Missing", "RPM")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(8, "Subscirber\'s Middle Name - Incorrect", "NNI")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(8, "Subscriber\'s suffix - Missing", "NNI")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(6, "Subscriber\'s suffix - Incorrect", "NPI")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(6, "Provider\'s Middle Name Missing", "HDM")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(6, "Provider\'s Middle Name Incorrect", "DGI")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(5, "Provider\'s Suffix Incorrect", "DGM")'
      execute 'INSERT INTO eob_errors(severity,error_type,code) VALUES(5, "Provider\'s Suffix Missing", "ANI")'
  end

  def down
    EobError.delete_all
  end
end
