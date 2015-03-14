class OperationLog::Config

  attr_reader :file_name, :format, :content_layout, :group_by, 
    :header_fields, :custom_header_fields, :summary_fields, :summary_position,
    :summarize_by, :quote_prefixed,:show_summary_header,:summary_header, :total, :primary_group,
    :for_date, :for_facility,:batch_total,:payer_total,:grand_total,:deposit_total,
    :by_cpid, :by_nextgen, :without_batch_grouping, :print_plb,:folder_name,
    :print_reject_check, :job_status_grouping, :by_client_and_deposit_date


  def initialize hash
    @config_hash = hash
    process_config
  end  

  def get_label_for header
    if @header_fields.collect(&:first).include?(header)
      @header_fields.map{|f|f[1]}[@header_fields.collect(&:first).index(header)]
    else
      nil
    end
  end

  def get_label_for_total total
    if @total.collect(&:first).include?(total)
      @total.map{|f|f[1]}[@total.collect(&:first).index(total)]
    else
      nil
    end
  end

  private  
  
  def process_config
    get_db_fields
    get_custom_fields
    get_other_configs
  end

  
  def get_db_fields
    @header_fields = []
    @config_hash["header"].keys.sort{|a,b| a.to_i <=> b.to_i}.each do |key|
      @header_fields << [@config_hash["header"][key], @config_hash["header_label"][key], @config_hash["header_rules"][key]] if @config_hash["header"][key].present?
    end    
  end



  def get_custom_fields
    @custom_header_fields = []
    @config_hash["custom_header"].keys.sort{|a,b| a.to_i <=> b.to_i}.each do |key|
      @custom_header_fields << @config_hash["custom_header"][key] 
    end    
    val = @custom_header_fields.pop
    while @custom_header_fields.size > 0 && val.blank?
      val = @custom_header_fields.pop
    end
    @custom_header_fields << val if val.present?
  end

  def get_other_configs
    Output835.oplog_log.info "Getting Configs..."
    @file_name = @config_hash["file_name_format"]
    @folder_name = @config_hash["folder_name_format"]
    @format = @config_hash["oplogformat"]
    @content_layout = @config_hash["content_layout"]
    Output835.oplog_log.info "Content layout: #{@content_layout}"
    @group_by = @config_hash["group_by"].values.uniq.select{|r| r.present?}
    Output835.oplog_log.info "Grouping: #{@group_by}"
    @print_plb = @config_hash["print_plb"]
    @print_reject_check = @config_hash["print_reject_check"]
    @job_status_grouping = @config_hash["job_status_grouping"]
       
    @summary_fields = []    
    @config_hash["summary_field"].keys.sort{|a,b| a.to_i <=> b.to_i}.each do |key|
      if @config_hash["summary_field"][key].present?
        @summary_fields << ([@config_hash["summary_field"][key], @config_hash["summary_field_label"][key]].select{|f| f.first.present?}.uniq)
      end
    end
    
    @summarize_by = @config_hash["summarize_by"]
    @summary_position = @config_hash["summary_position"] 
    @quote_prefixed = @config_hash["prefix_quotes"].present? && @format !="xls" && @format !="xlsx"
    @show_summary_header = @config_hash["summary_header"].present? && @config_hash["summary_header"] != "NOLABEL" 
    @summary_header = @show_summary_header ?  @config_hash["summary_header"] : ""
    

    @total = []
    @config_hash["total"].keys.sort{|a,b| a.to_i <=> b.to_i}.each do |key|
      @total << [@config_hash["total"][key], @config_hash["total_label"][key]] if @config_hash["total"][key].present?
    end    

    {"batch_total"=>"Batch Total","grand_total"=>"Grand Total","deposit_total"=>"Deposit Total","payer_total"=>"Payer Total"}.each do |k,v|
      if @total.collect(&:first).include?(v)
        eval("@#{k}=true")
      else
        eval("@#{k}=false")
      end
    end

    @primary_group = (group_by.include?("payer") || group_by.include?("payer (cpid)")) ?  "payer" : "batch"    
    @by_cpid = group_by.include?("payer (cpid)")
    @without_batch_grouping = group_by.include?("batch") ? false : true
    @for_date = group_by.include?("batch date")
    @for_facility = group_by.include?("facility")
    @by_nextgen = group_by.include?("nextgen")
    @by_client_and_deposit_date = group_by.include?("client and deposit date")
  end
  
end

