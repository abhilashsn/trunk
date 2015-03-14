require 'csv'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which columns
# of the csv file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IdxCsvShepherdParser < InputBatch::IndexCsvTransformer
  attr_accessor :csv, :cnf, :type, :facility, :row

  # method to find batchid
  def find_batchid
    string = parse(conf['BATCH']['batchid'])
    if string != nil
    batchid = string.split("_").last rescue nil
    date = parse(conf['BATCH']['date'][0])
    bat_date = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
    "#{batchid}_#{bat_date}"
    else
    @batchid
    end
  end

  # method to find the type of batch corresponce or payment
  def find_type
    check_number = parse(cnf['PAYMENT']['CHEQUE']['check_number'])
    check_amount = parse(cnf['PAYMENT']['CHEQUE']['check_amount'])
    if !check_number.blank? or !check_amount.blank?
    condition = (check_number.squeeze == '0' and parse_amount(check_amount) == 0.0)
    else
      condition = (@squeezed_check_number == '0' and @parsed_amount == 0.0)
    end
    @squeezed_check_number = check_number.squeeze if !check_number.blank?
    @parsed_amount = parse_amount(check_amount) if !check_amount.blank?
    @type = condition ? 'CORRESP' : 'PAYMENT'
  end

  def job_condition
    if parse(conf["JOB"]["check_number"]) != nil
      true
    end
  end

end