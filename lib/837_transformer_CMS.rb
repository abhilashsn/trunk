require 'nokogiri'
require 'lib\837_transformer.rb'

class Transformer_837_CMS < Transformer_837

  private
  
  def process_claim clms
    log.info " ..Processing Claim of patient: #{clms.xpath(cnf['CLAIM']['patient_names']).text}"
    clm = ClaimInformation.new
    cnf["CLAIM"].each do |k,v| 
      case k
        when "patient_names"
          frame_patient_names(clm,clms.xpath(v).text)
        when "subscriber_names"
          frame_subscriber_names(clm,clms.xpath(v).text)
        when "provider_names"
          frame_provider_names(clm,clms.xpath(v).text)
        else
          clm[k] = clms.xpath(v).text 
        end
    end
    return clm
  end
   
  def frame_patient_names(rec, val)
    unless val.blank?
      tmp = val.split(",") 
      rec["patient_last_name"] = tmp[0].strip
      rec["patient_first_name"] = tmp[1].strip
    end
  end

  def frame_subscriber_names(rec, val)
    unless val.blank?
      tmp = val.split(",") 
      rec["subscriber_last_name"] = tmp[0].strip
      rec["subscriber_first_name"] = tmp[1].strip
    end
  end
  
  def frame_provider_names(rec, val)
    unless val.blank?
      tmp = val.split
      rec["provider_first_name"] = tmp[0].strip
      rec["provider_middle_initial"] = tmp[1].strip
      rec["provider_last_name"] = tmp[2].strip
    end
  end

end #class

if ARGV.length > 0
  trnsf = Transformer_837_CMS.new(ARGV[0],ARGV[1])
  trnsf.transform
else
  puts "ERROR::Unable to process without 837 input file!"
end
