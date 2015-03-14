class Output835::MedassetsDocument < Output835::Document  
  
  def functional_group_header
    batch_date = checks.first.job.batch.date
    facility_name = facility.name.upcase.slice(0, 15)
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << payer_id
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      gs_03 = (@facility_config.details[:payee_name]).strip
    else
      gs_03 = facility_name.strip
    end
    gs_elements << gs_03
    # giving batch date instead of file generating date in the generic template
    gs_elements << batch_date.strftime("%Y%m%d")
    gs_elements << Time.now.strftime("%H%M")
    gs_elements << '2831'
    gs_elements << 'X'
    gs_elements << ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')
    gs_elements = Output835.trim_segment(gs_elements)
    gs_elements.join(@element_seperator)
  end

  def payer_id
    payer = checks.first.payer
    job = checks.first.job
    payer_type = (payer ? job.payer_group  : nil)
    output_config = facility.output_config(payer_type)
    payid = output_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      if $IS_PARTNER_BAC
        @facility_config.predefined_payer.to_s
      elsif facility.index_file_parser_type == 'Barnabas'
        payer.output_payid(facility) if payer
      else
         payer.supply_payid if payer
      end
    else
      payid.to_s
    end
  end
  
end