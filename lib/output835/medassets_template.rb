class Output835::MedassetsTemplate < Output835::Template

  def functional_group_header
    ['GS', 'HP', payer_id, strip_string(gs_03), @batch.date.strftime("%Y%m%d"), Time.now.strftime("%H%M"),
        '2831', 'X', ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].trim_segment.join(@element_seperator)
  end

  def payer_id
    payer = @first_check.payer
    job = @first_check.job
    payer_type = (payer ? job.payer_group : nil)
    payid = @facility_output_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      if @facility.index_file_parser_type == 'Barnabas'
        payer.output_payid(@facility) if payer
      else
         payer.supply_payid if payer
      end
    else
      payid.to_s
    end
  end

end