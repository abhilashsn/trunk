class InputBatch::IdxCsvTransformerCarisMolecularProfilingInstitute < InputBatch::IdxCsvQuadaxCustomFilePathParser
  attr_reader :csv, :cnf, :type, :facility, :row
  
  
  

  
  
    
  
  
  
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



