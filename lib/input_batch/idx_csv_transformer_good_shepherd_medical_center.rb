class InputBatch::IdxCsvTransformerGoodShepherdMedicalCenter< InputBatch::IndexCsvTransformer

  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    set_initial_image_name if @initial_image_name
    return images
  end

  #This modification is added as per request from Operations and the updates are mentioned in ticket #26940
  def set_initial_image_name
    img_extension = @initial_image_name.split('.').last
    img_name_pieces = @initial_image_name.split('.').first.split('_')
    batch_id = get_batchid.to_s
    img_seq_number = img_name_pieces[img_name_pieces.index(batch_id.to_s) + 1].to_i.to_s
    @initial_image_name = batch_id + img_seq_number + '.' + img_extension
  end

end
