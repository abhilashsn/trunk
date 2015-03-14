module OutputPayer

  def get_sender_id facility
    if facility.index_file_parser_type == 'Barnabas'
      payid = output_payid(@facility)
    elsif facility.client.name == "PACIFIC DENTAL SERVICES"
      payid = gcbs_output_payid(@facility)
    else
      payid = supply_payid
    end
    payid.to_s.justify(15)
  end

end