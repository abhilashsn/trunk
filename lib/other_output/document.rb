class OtherOutput::Document
  attr_accessor :image_types, :facility, :facility_name, :batch_ids, :config, :row_count, :accumulated_batch_ids

  def initialize batch_id, config 
    @batch_id = batch_id    
    @facility =  Batch.find(@batch_id).facility
    @config = config
    @generate = false
    @accumulated_batch_ids = get_batch_ids(@batch_id, @config.grouping)            
    @generate = true if @accumulated_batch_ids.present?
    if @generate
      facility_name = @facility && @facility.name ? @facility.name : "unknown"
      @other_outputs_directory = "private/datanew/other_outputs/#{facility_name}/#{@config.format}/#{@config.report_type}/#{Date.today.to_s}"    
      if @config.report_type == "A36 Report"
        @image_types = ImageType.all_image_types_by_batch_ids @accumulated_batch_ids
      else
        @image_types = ImageType.by_batch_ids @accumulated_batch_ids
      end
      @filename = parse_file_name 
      @zip_filename =  @config.zip_file_name.present? ?  parse_zip_file_name  : false
      @row_count = 0
      extend("OtherOutput::DataFetcher#{@config.report_type.split(" ")[0]}".constantize) rescue nil
    end
  end
  

  def generate_file
    return if !@generate
    FileUtils.mkdir_p(@other_outputs_directory)
    file_name =  @filename
    writer = get_document_writer 
    File.open(file_name, "w+") do |f|
      new_headers_fields = insert_service_line_headers (@config.header_fields)
      f << writer.header(new_headers_fields)
      generate_content do | image_type |        
        load_objects image_type
        puts @config.report_type
        if @config.report_type == "A37 Report" #this is a hack to run the iterator over service_paymen_eobs and render lines that are redendent except @service_payment_eob
          @service_payment_eobs.each do |service_payment_eob|
            @service_payment_eob = service_payment_eob
            f << writer.line(new_headers_fields, evaluate_row_from_headers(image_type))
          end
        else
          f << writer.line(new_headers_fields, evaluate_row_from_headers(image_type))
        end
      end
    end
    file_name
  end

  def get_zip_file_name
    @zip_filename
  end
    
  private

  def get_batch_ids batch_id, grouping
    batch = Batch.find(batch_id)
    batch_ids = []
    if grouping == "batch"
      batch_ids = [batch_id]
    elsif grouping == "batch date"
      batch_ids = Batch.find_all_by_date_and_facility_id(batch.date,batch.facility_id).collect(&:id)
    elsif grouping == "cut"
      if batch.cut 
        batch_ids = Batch.find_all_by_cut_and_facility_id_and_date(batch.cut, batch.facility_id, batch.date).collect(&:id)
      else
        puts "cut is nil"
        batch_ids = [batch.id]
      end
    else
      batch_ids = []
    end
    batch_ids = Batch.batches_with_qualified_jobs(batch_ids).collect(&:id) if batch_ids.present?
    batch_ids
  end


  def parse_file_name
    facility = @facility
    batch = Batch.find(@batch_id)
    first_batch = Batch.find(@accumulated_batch_ids.first)
    batchid = batch.real_batch_id
    batch_date = batch.date
    filename_hash = {
      "[Batch date(YMMDD)]" => batch_date.strftime("%y%m%d")[1..-1],
      "[Batch date(MMDD)]" => batch_date.strftime("%m%d"),
      "[3-SITE]" => facility.sitecode.slice(2,3),
      "[Cut]" => batch.cut,
      "[Lockbox Number]" => facility.lockbox_number,
      "[EXT]" => first_batch.correspondence == true ? "COR" : "PAY",
      "[NNN]" => first_batch.index_batch_number ? first_batch.index_batch_number.to_s.rjust(3,"0") : ""
    }

    filename = @config.file_name
     filename_hash.each do |key,value|
       filename.gsub!("#{key}","#{value}") if filename && filename.include?("#{key}")
     end
    puts @config.format.downcase
    filename = "#{filename}.#{@config.format.downcase}"        
    @other_outputs_directory + "/" + filename
  end
  
  def parse_zip_file_name
    facility = @facility
    batch = Batch.find(@batch_id)
    first_batch = Batch.find(@accumulated_batch_ids.first)
    batchid = batch.real_batch_id
    batch_date = batch.date
    filename_hash = {
      "[Batch date(YMMDD)]" => batch_date.strftime("%y%m%d")[1..-1],
      "[Batch date(MMDD)]" => batch_date.strftime("%m%d"),
      "[3-SITE]" => facility.sitecode.slice(2,3),
      "[Cut]" => batch.cut,
      "[Lockbox Number]" => facility.lockbox_number,
      "[NNN]" => first_batch.index_batch_number ? first_batch.index_batch_number.to_s : ""
    }

    filename = @config.zip_file_name
    filename_hash.each do |key,value|
      filename.gsub!("#{key}","#{value}") if filename && filename.include?("#{key}")
    end
    filename = "#{filename}.zip"
    @other_outputs_directory + "/" + filename    
  end




  def get_document_writer
    @writer ||= OtherOutput::CsvDocument.new    
  end
  
  def generate_content
    @image_types.each do |image_type|
      @row_count = @row_count + 1
      yield image_type
    end
  end


  def evaluate_row_from_headers image_type
    insert_service_line_values(Hash[*(config.header_fields.collect(&:first).zip(
                 config.header_fields.map{|f| self.send("eval_" + f.first.downcase.gsub(/[^a-zA-Z ]/, "").strip.gsub(" ", "_"))})).flatten],
                                @config.header_fields)
  end


  def load_objects image_type
    
  end

  def insert_service_line_headers fields
      fields
  end

  def insert_service_line_values hsh,fields
      hsh
  end  

end
