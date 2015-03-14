class Output835::NavicureTemplate < Output835::Template

  # This is the business identification information for the transaction
  # receiver. This may be different than the EDI address or identifier of the receiver
  def reciever_id
    [ 'REF', 'EV', @job.original_file_name.to_s[0...50]].trim_segment.join(@element_seperator) if @job.initial_image_name
  end


end