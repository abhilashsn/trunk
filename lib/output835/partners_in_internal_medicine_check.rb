# To change this template, choose Tools | Templates
# and open the template in the editor.

class Output835::PartnersInInternalMedicineCheck< Output835::Check
  def ref_ev_loop
    if check.check_amount > 0
      image_name = check.job.images_for_jobs.last.filename rescue nil
    else
      image_name = check.job.images_for_jobs.first.filename rescue nil
    end
    ['REF','EV', image_name.to_s[0...50]].join(@element_seperator)
  end
end
