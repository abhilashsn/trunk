# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxCsvTransformerWellstarLaboratoryServices < InputBatch::IdxCsvQuadaxCustomFilePathParser

  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    if type == "CORRESP"
      path = Dir.glob("#{@location}/**/corr/corr#{image.filename}.[T,t][I,i][F,f]")[0]
    else
      path = Dir.glob("#{@location}/**/images/images#{image.filename}.[T,t][I,i][F,f]")[0]
    end
    image_file_name = path.strip.split("\\").last unless path.blank?
    count = %x[identify "#{path}"].split(image_file_name).length-1
    new_image_name = File.basename("#{path}")
    initial_image_name_for_job = new_image_name
    if count>1
      dir_location = File.dirname("#{path}")
      ext_name = File.extname("#{path}")
      new_image_base_name = new_image_name.chomp("#{ext_name}")
      InputBatch.split_image(count,path, dir_location, new_image_base_name)
        single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
        single_images.each_with_index do |single_image, index|
          new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
          File.rename(single_image, new_image_name)
          image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
          @img_count += 1
          images << image
        end
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
      images << image
    end
    return images,initial_image_name_for_job
  end




end
