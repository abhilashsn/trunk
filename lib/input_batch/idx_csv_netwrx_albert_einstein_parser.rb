require 'csv'
require 'yaml'
require 'input_batch'

class  InputBatch::IdxCsvNetwrxAlbertEinsteinParser< InputBatch::IndexCsvTransformer
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

  #this method is used to get the single image based on condition
  def get_single_image(file, new_image_base_name)
    if File.basename(file).split('.').count > 2
      name_array = File.basename(file).split('.')
      name_array.pop
      image_file_name = name_array*'.'
      image_file_name =~ /#{new_image_base_name}[0-9][0-9][0-9][0-9]/
    else
      File.basename(file).split('.').first =~ /#{new_image_base_name}[0-9][0-9][0-9][0-9]/
    end
  end

  #this method will use tiffcp in spite of tiffsplit to avoid exceptions for some kind of tiff files
  def split_image(count, path, dir_location, new_image_base_name)
    count.times do |i|
      value = "#{i}".rjust(4,'0')
      system("tiffcp #{path},'#{i}' #{dir_location}/#{new_image_base_name}#{value}.tif")
    end
  end

end