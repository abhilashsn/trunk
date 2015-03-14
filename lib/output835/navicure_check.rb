#Represents an ST-SE Transaction
class Output835::NavicureCheck < Output835::Check

  # This is the business identification information for the transaction
  # receiver. This may be different than the EDI address or identifier of the receiver
  def reciever_id
    image_ref = check.job.client_images_to_jobs.first if check.job.client_images_to_jobs.length > 0
    image = image_ref.images_for_job if (image_ref && image_ref.images_for_job)
    if image && image.filename
      elements = []
      elements << 'REF'
      elements << 'EV'
      elements << image.original_file_name[0...50]
      elements = Output835.trim_segment(elements)
      elements.join(@element_seperator)
    end
  end

end