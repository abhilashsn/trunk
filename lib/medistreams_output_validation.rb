##################################################################################################################################
#   Description: Ruby Script to validate Medistreams XML output file. The Scripts picks up all xml file from a source folder,
#   conducts validations and log info and error type messages to output log file.
#
#   Created   : 2010-07-16 by Rajesh R @ Revenuemed
#
##################################################################################################################################
require 'rubygems'
require 'nokogiri'
require 'logger'
require 'yaml'

# Reading the input folder path and output folder path from YML config file
cnf = YAML::load(File.open("medistream_output_validation.yml"))
input_dir = cnf ["PATH"]["INPUT"]
output_dir = cnf ["PATH"]["OUTPUT"]
# Defining output log file
log = Logger.new("#{output_dir}/MedistreamsOutputValidationResult.log", "daily")

log.info "######################################################################################################################"
log.info "Validation Begins"

Dir.glob("#{input_dir}/*.xml").each do |filename|

  log.info "File Name - " + filename.to_s
  xml_output = File.open(filename)
  doc = Nokogiri::XML(xml_output)
  log.info "Opened XML document for processing"

  # initializing variableS
  total_claim_charge = 0.0
  total_line_item_payment = 0.0
  total_adjustment_amount = 0.0

  # Iterating through /<MediStreams.Remittance>/<Batch>/<Transaction> tags
  doc.xpath("/MediStreams.Remittance/Batch/Transaction").each do |transaction|
    transaction_control_number = transaction.xpath("TransactionControlNumber").text.strip
    check_amount = transaction.xpath("CheckAmount").text.strip.to_f
    image_type = transaction.xpath("Image_Type").text.strip
    total_claim_payment = 0.0
    # Iterating through /<MediStreams.Remittance>/<Batch>/<Transaction>/<Claim tags>
    transaction.xpath("Claim").each do |claim|
      patient_account_number = claim.xpath("PatientAccountNumber").text.strip
      # Fetching Total claim charge amount
      total_claim_charge = claim.xpath("TotalClaimCharges").text.strip.to_f
      # Fetching Total Claim Payment amount
      claim_payment = claim.xpath("TotalClaimPayment").text.strip.to_f
      total_claim_payment = total_claim_payment + claim_payment
      # initializing variable that holds total line item payment variable
      total_line_item_payment = 0.0
      # initializing variable that holds total adjustment amount variable
      total_adjustment_amount = 0.0
      claim.xpath("Line").each do |line|
        line_item_payment = line.xpath("LineItemPayment").text.strip.to_f
        total_line_item_payment = total_line_item_payment + line_item_payment
        line.xpath("Adjustment").each do |adjustment|
          adjustment_amount = adjustment.xpath("AdjustmentAmount").text.strip.to_f
          total_adjustment_amount = total_adjustment_amount + adjustment_amount
        end
      end
      # Validating the rule - <TotalClaimCharges> amount = Sum of all <LineItemPayment> amounts + Sum of all <AdjustmentAmount> amounts
      total_line_adjustment = total_line_item_payment + total_adjustment_amount
      total_claim_charge =  (100*total_claim_charge).round/100.0
      total_line_adjustment =  (100*total_line_adjustment).round/100.0

      unless (total_claim_charge - total_line_adjustment == 0)
        log.info "*********************************************"
        log.info "TransactionControlNumber [#{transaction_control_number}], PatientAccountNumber [#{patient_account_number}]."
        log.info "TOTAL CLAIM CHARGE = " + total_claim_charge.to_s
        log.info "TOTAL LINE ITEM PAYMENT = " + total_line_item_payment.to_s
        log.info "TOTAL ADJUSTMENT AMOUNT = " + total_adjustment_amount.to_s
        log.info "TOTAL LINE AMOUNTS + ADJUSTMENT AMOUNTS = " + total_line_adjustment.to_s
        log.error "TotalClaimCharges does not match the sum of total payments and total adjustment amounts for the lines in TransactionControlNumber [#{transaction_control_number}], and PatientAccountNumber [#{patient_account_number}]."
        log.info "IMAGE TYPE - " + image_type.to_s
        log.info "*********************************************"
      else
        log.info "---------------------------------------------"
        log.info "TransactionControlNumber [#{transaction_control_number}], PatientAccountNumber [#{patient_account_number}]."
        log.info "TOTAL CLAIM CHARGE = " + total_claim_charge.to_s
        log.info "TOTAL LINE ITEM PAYMENT = " + total_line_item_payment.to_s
        log.info "TOTAL ADJUSTMENT AMOUNT = " + total_adjustment_amount.to_s
        log.info "---------------------------------------------"
      end
    end
    # Validating the rule - <CheckAmount> amount = Sum of all <TotalClaimPayment> amounts
    check_amount =  (100*check_amount).round/100.0
    total_claim_payment =  (100*total_claim_payment).round/100.0

    unless (check_amount - total_claim_payment == 0)
      log.info "*********************************************"
      log.info "TransactionControlNumber [#{transaction_control_number}]."
      log.info "CHECK AMOUNT = " + check_amount.to_s
      log.info "TOTAL CLAIM PAYMENT = " + total_claim_payment.to_s
      log.error "Check Amount does not match the sum of TotalClaimPayments in TransactionControlNumber [#{transaction_control_number}]."
      log.info "IMAGE TYPE - " + image_type.to_s
      log.info "*********************************************"
    else
      log.info "---------------------------------------------"
      log.info "TransactionControlNumber [#{transaction_control_number}]."
      log.info "CHECK AMOUNT = " + check_amount.to_s
      log.info "TOTAL CLAIM PAYMENT = " + total_claim_payment.to_s
      log.info "---------------------------------------------"
    end
  end
end
log.info "Validation Completed"
log.info "######################################################################################################################\n\n"

