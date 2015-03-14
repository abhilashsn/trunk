class InputBatch::IdxCsvTransformerMeritMountainside< InputBatch::IdxCsvNavicureBasicParser
  
  def prepare_image
    images = []
    single_page_images = convert_multipage_to_singlepage
    single_page_images.each do |image_file|
      image = ImagesForJob.new
      image.filename = File.basename(image_file)
      image.is_splitted_image = true
      image = update_image image
      images << image
    end
    return images
  end

  def convert_multipage_to_singlepage
    current_job_image = Dir.glob("#{@location}/**/*").select{|file| File.basename(file) == parse(conf["IMAGE"]['image_file_name'])}[0]
    dir_name = File.dirname(current_job_image)
    file_name = File.basename(current_job_image).split('.').first
     @initial_image_name = file_name
    system("tiffsplit #{current_job_image} #{dir_name}/#{file_name}")
    Dir.glob("#{@location}/**/*").select{|file| File.basename(file).split('.').first =~ /#{file_name}[a-z][a-z][a-z]/}.sort
  end
  

end
