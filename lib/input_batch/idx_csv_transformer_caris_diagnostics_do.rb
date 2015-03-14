class InputBatch::IdxCsvTransformerCarisDiagnosticsDo < InputBatch::IdxCsvQuadaxCustomFilePathParser 
  attr_reader :csv, :cnf, :type, :facility, :row
  
  #### methods for setting values which are not parsed from index file during batch loading ####
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    #bat.date = facility.batches.last.date if bat.date.blank?
    bat.date = Date.today
    bat.bank_deposit_date = facility.batches.last.date if bat.bank_deposit_date.blank?
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end
  
  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    path =  Dir.glob("#{@location}/**/#{image_file_name}").first
    count = %x[identify "#{path}"].split(image_file_name).length-1
    new_image_name = File.basename("#{path}")
    if count>1
      dir_location = File.dirname("#{path}")
      ext_name = File.extname("#{path}")
      new_image_base_name = new_image_name.chomp("#{ext_name}")
      if ((not ext_name.empty?) and (ext_name.casecmp(".pdf") == 0) ) then
        system "pdftk  '#{path}' burst output '#{dir_location}/#{new_image_base_name}_%d#{ext_name}'"
        for image_count in 1..count
          image = ImagesForJob.new(:image_file_name=>"#{new_image_base_name}_#{image_count}#{ext_name}",:is_splitted_image=>true)
          image = update_image image
          images << image
        end
      else
        InputBatch.split_image(count,path, dir_location, new_image_base_name)
        single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
        single_images.each_with_index do |single_image, index|
          new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
          File.rename(single_image, new_image_name)
          image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
          @img_count += 1
          images << image
        end
      end
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
      images << image
    end
    return images,image_file_name
  end
  
  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    if type == "CORRESP"
      image_path = Dir.glob("#{@location}/**/corr/corr#{image.filename}.[T,t][I,i][F,f]")[0]
    else
      image_path = Dir.glob("#{@location}/**/images/images#{image.filename}.[T,t][I,i][F,f]")[0] 
    end
    image.image_file_name = File.basename(image_path)
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    @img_count += 1
    if Dir.glob("#{@location}/**/#{image.filename}")[0]
      InputBatch.log.info "Image #{image.filename} found"
    else
      InputBatch.log.info "Image #{image.filename} not found"
    end
    return image
  end
  
end #class



