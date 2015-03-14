class InputBatch::IdxCsvQuadaxParser  < InputBatch::IndexCsvTransformer

def process_csv cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    csv.each do |row|
      @row = row
      if row[7].upcase!= "R"
      save_records
      end
    end
    csv.close
  end

  def prepare_image
    images = []
    if parse(conf['JOB']['record_type']) == "C"
      image = ImagesForJob.new
      cnf[type]['IMAGE'].each do |k,v|
        image[k] = parse(v[0])
      end
      image = update_image image
       if @job_condition
         @initial_image_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
       end
      images << image
    else
      conf['IMAGE']['image_file_name'].each do |img|
        unless parse(img).blank?
          image = ImagesForJob.new
          conf['IMAGE'].each do |k,v|
            image[k] = (k == "image_file_name") ? parse(img) : parse(v)
          end
          image = update_image image
          if @job_condition
            @initial_image_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
          end
          images << image
        end
      end
    end
    return images
  end

  def get_batchid
    batchid = parse(conf['BATCH']['batchid'])
    date = parse(conf['BATCH']['date'][0])
    batchid = "#{batchid}_#{date}"
  end

  def parse_amount amount_str
    amount = amount_str.strip
    if amount =~ /[A-Za-z]/
      0.0
    else
      amount.to_f
    end
  end

end