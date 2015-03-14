FactoryGirl.define do
  factory :facopconf, class: FacilityOutputConfig do
      facility_id  11
      eob_type  'Insurance EOB'
      file_name  "PM_PATHOLOGY MEDICAL SERVICES_2342_Operation Log"
      details
              statement_number  true
              configurable_835  true
              isa_06  'Predefined Payer ID'
              isa_segment 
                  '1'  '00'
                  '3'  '00'
                  '5'  'ZZ'
                  '6'  '[CPID From 837]'
                  '7'  'ZZ'
                  '8'  '[Client TIN]'
                  '11'   'U'
                  '12'   '00401'
                  '13'  '[Counter]'
                  '14'  '0'
                  '15'  'P'
                  '16'  '&&'
              trn_segment 
                  '2'  '[Batch ID]'
                  '3'  '[1 + Payer TIN]'
              nm182_segment
                  '2'  '1'
                  '3'  '[Provider Last Name]'
                  '4'  '[Provider First Name]'
                  '5'  '[Provider Middle Initial]'
                  '7'  '[Provider Suffix]'
                  '9'  '[Patient First Name]'
              svc_segment  
                  '5'  '[True]'
              n3pr_segment 
                  '01'  "[Payer Address]"
              n4pr_segment 
                  '01'  "[Payer City]"
                  '02'  "[Payer State]"
                  '03'  "[Payer ZipCode]"
              amtb6_segment
                  '2'  '[Supplemental Amount]'
              reftj_segment
                  '1'  'TJ'
                  '2'  "[Legacy Provider Number]"
              lx_segment
                  '1'  "2"
              amti_segment
                   '2'  "[Monetary Amount(Interest)]"
              nm1il_segment  
                   '8'  "MI"
                   '9'  "[Member ID]"
              cas_segment  
                   '1'  '1'
                   '2'  '2'
                   '4'  '4'
              refck_segment  
                    '1'  'CK'
                    '2'  '[Provider TIN]'
              refev_segment  
                    '2'  '[Check Image ID]'
              reff8_segment  
                     '2'  '[Image Page Name]'
              nm1pr_segment  
                     '1'  'PR'
                     '2'  '02'
                     '3'  '[Corrected Priority Payer Name]'
                     '8'  '08'
                     '9'  '[Rendering Provider Identifier]'
              dtm151_segment  
                     '2'  '[Service To Date]'
              dtm150_segment  
                     '2'  '[Service Date]'
              refsi_segment  
                     '1'  'SI'
                     '2'  '[Submitter Identification Number]'
              amtau_segment  
                     '2'  '[Claim Level Allowed Amount]'
              dtm233_segment  
                     '2'  '[Service To Date]'
              end 
end