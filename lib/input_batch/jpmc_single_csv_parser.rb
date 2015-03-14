class InputBatch::JpmcSingleCsvParser < InputBatch::IndexCsvTransformer


  def prepare_image
    images = []
    if parse(conf['JOB']['record_type']) == "C"
      image = ImagesForJob.new
      cnf[type]['IMAGE'].each do |k,v|
        image[k] = parse(v[0])
      end
      image = update_image image
      images << image
    else
      conf['IMAGE']['image_file_name'].each do |img|
        unless parse(img).blank?
          image = ImagesForJob.new
          conf['IMAGE'].each do |k,v|
            image[k] = (k == "image_file_name") ? parse(img) : parse(v)
          end
          image = update_image image
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
