module Package
  class Rapackage
    attr_accessor :batch

    def initialize batch
      @batch = batch
      @directory = Rails.root.to_s + "/private/data/RAPackage/#{@batch.id.to_s}/"
    end


    def generate(final_dir_location)
      puts "Collecting the images, 835s, edcxmls, a37s and hreobs..............."
      output_activity_log = @batch.output_activity_logs.create(:start_time => Time.now, 
                                                               :estimated_end_time => estimated_completion_time, :file_name=> zip_file_name, 
                                                               :file_format => "RA", :file_location => final_dir_location['target_dir'],
                                                               :status=>OutputActivityStatus::GENERATING)

      get_images      
      FileUtils.mkdir_p(@directory+ "tmp")
      FileUtils.mkdir_p(@directory + "temp/docs")
      @zip_name = "\"" + @directory +  zip_file_name + "\""     
      zip= Array.new
      base =  File.basename(@edcxmls.first)
      splits = base.split("_")
      zip << splits.pop.gsub("XML", "ZIP")
      zip << splits.pop
      @edc_xml_zip_name = "EDC_" + zip.reverse.join("_")
      @edc_xml_zip = "\"" + @directory + "tmp/" + @edc_xml_zip_name + "\""       
      archive(final_dir_location)
      output_activity_log.mark_generated_with_checksum Time.now
      output_activity_log.mark_uploaded
    end

    def archive(final_dir_location)
      @edcxmls.each do |file|
        system "cp \"#{Rails.root.to_s  + file}\" #{@directory + "tmp"}"
      end
      #return
      #system "touch #{@directory + "tmp/one.xml"} #{@directory + "tmp/one.XML"}" 
      Dir.chdir("#{@directory}" + "tmp")
      #system "zip -q #{@directory + "tmp/edcxmls.zip"} #{@directory + "tmp/" + "*.xml"} #{@directory + "tmp/" +  "*.XML"}"
      system "zip -q #{@edc_xml_zip_name} *.XML"
      system "cp #{@edc_xml_zip} #{@directory + "temp"}"
      (@images + @f835s + @a37s + @hreobs).each do |file|
        if Dir.glob(Rails.root.to_s  + file).blank?
          Dir.chdir(Rails.root.to_s  +  File.dirname(file))
          system "unzip *.PAY" rescue nil
          system "unzip *.COR" rescue nil
          Dir.chdir(Rails.root.to_s)
        end
        system "cp \"#{Rails.root.to_s  + file}\" #{@directory + "temp/docs"}"
      end
      Dir.chdir("#{@directory}" + "temp")
      system "zip -r #{@zip_name} docs #{@edc_xml_zip_name}"
      FileUtils.rm_r( (@directory + "tmp"), :force => true)
      FileUtils.rm_r( (@directory + "temp"), :force => true)
      Dir.chdir(Rails.root.to_s)
      system "mv #{@directory}*.ZIP #{final_dir_location['target_dir']}"
    end

    def get_images
      @images = ImagesForJob.where("batch_id = #{@batch.id}").map{|j| j.image.path.gsub(Rails.root.to_s, "")}.uniq
      @f835s = OutputActivityLog.where("batch_id = #{@batch.id} AND file_format='835_source'").map{|j| j.file_location + "/" + j.file_name}.uniq.map{|j| "/" + j}
      @edcxmls =  OutputActivityLog.where("batch_id = #{@batch.id} AND file_format='ETL_XML'").order("start_time desc")[0,4].map{|j| j.file_location + "/" + j.file_name}.uniq.map{|j| "/" + j}
      @a37s = OutputActivityLog.where("batch_id = #{@batch.id} AND file_format='A37'").map{|j| j.file_location + "/" + j.file_name}.uniq.map{|j| "/" + j}
      #@a36s = OutputActivityLog.where("batch_id = #{@batch.id} AND file_format='A36'").map{|j| j.file_location + "/" + j.file_name}.uniq.map{|j| "/" + j}
      @hreobs = OutputActivityLog.where("batch_id = #{@batch.id} AND file_format='HREOB'").map{|j| j.file_location + "/" + j.file_name}.uniq.map{|j| "/" + j}
      puts "The Images are................................................."
      puts @images
      puts "The 835s are................................................."
      puts @f835s
      puts "The EDC XMLs are................................................."
      puts @edcxmls
      puts "The A37s are................................................."
      puts @a37s
      puts "The HREOBs are................................................."
      puts @hreobs
    end
    
    private
    def estimated_completion_time
      Time.now + 100
    end
    
    def zip_file_name
      @zipfilename ||= 'RA_%s_%s_%s%s%s_%s_%s_%s.ZIP' % ["EDC", "RM", @batch.date.strftime("%y%m%d"), (@batch.cut ? @batch.cut.rjust(2, '0') : "XX"),
                                                           (@batch.facility ? @batch.facility.sitecode : ""), "%03d" % @batch.index_batch_number,
                                                           Time.now.strftime("%Y%m%d"), Time.now.strftime("%H%M%S")]
      @zipfilename
    end
  end
end
