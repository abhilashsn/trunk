class InputBatch::IdxCsvTransformerJpmc < InputBatch::IndexCsvTransformer


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
      conf['IMAGE']['filename'].each do |img|
        unless parse(img).blank?
          image = ImagesForJob.new
          conf['IMAGE'].each do |k,v|
            image[k] = (k == "filename") ? parse(img) : parse(v)
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

end