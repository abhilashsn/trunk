# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxCsvTransformerBenefitRecovery < InputBatch::IndexCsvTransformer
    
  def process_csv cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    @micr_condition = true
    csv.each do |row|
      @row = row
      aba_routing_number = row[5]
      payer_account_number = row[1]
      if aba_routing_number.blank? or payer_account_number.blank?
        @micr_condition = false
      end
      unless @micr_condition
        InputBatch.log.info ">>MICR data is missing from the index file..."
        puts "MICR data is missing from the index file... "
        break
      end
    end
    csv.close
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    if @micr_condition
      csv.each do |row|
        @row = row
        save_records
      end
    end
    csv.close
  end
end
