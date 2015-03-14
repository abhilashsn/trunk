class Output835::PartnersInInternalMedicineTemplate< Output835::Template

  def ref_ev_loop
    #image_name = (@check.check_amount > 0 ? @job.images_for_jobs.last.exact_file_name : @job.images_for_jobs.first.exact_file_name)
    ['REF', 'EV', @job.initial_image_name.to_s[0...50]].trim_segment.join(@element_seperator) if @job.initial_image_name
  end
end
