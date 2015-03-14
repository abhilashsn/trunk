class ExceptionCheckPdf < Prawn::Document

	def initialize(batch, checks)
    super({:page_size => 'A3', :page_layout => :portrait})
    @checks = checks
    @batch = batch
    @batchid_array = @batch.batchid.split('_') unless @batch.batchid.blank?
    @deposit_date = Date.strptime @batchid_array[1], "%y%m%d" unless @batchid_array.blank?
    @deposit_date_formatted = @deposit_date.strftime("%m/%d/%Y")
    @batch_lockbox = @batch.lockbox
    date_details
    logo
    header_details
    lockbox_details
		exception_check_details
  end

  def logo
    move_down 15
    logopath =  "#{Rails.root}/app/assets/images/BNY_logo.jpg"
		image logopath, :width => 100, :height => 50
  end

  def date_details
    generated_date_time = Time.now.strftime('%m/%d/%Y %I:%M:%S %p')
    text "#{generated_date_time}", :size => 13, :align => :right
  end

  def header_details
    draw_text "Exceptions by Check for UPMC", :size => 14, :at => [260,1075]
  end

  def lockbox_details
    draw_text "Lockbox #{@batch_lockbox}  Deposit Date of #{@deposit_date_formatted}",
      :size => 13, :at => [260,1045]
  end

	def exception_check_details
		move_down 20
    table exception_check_item_rows, :position => :center, :width => 825 do
			row(0).background_color = "848484"
      row(0).font_style = :bold
      row(0).text_color = "FFFFFF"
      columns(1..5).align = :right
      row(0).align = :center
			self.header = true
      self.cell_style = {:size => 14}
      self.column_widths = {0 => 100, 1 => 230, 2 => 80, 3 => 65, 4 => 80,
         5 => 110, 6 => 160}
		end
    if @checks.length == 0
      move_down 20
      text "No Data Found. Please Check the Date Range and Lockbox and Try Again.",
        :color => "FF3300", :align => :center
    end
	end

  def exception_check_item_rows
    [["Deposit Date", "File Name", "Lockbox #", "Batch #", "Sequence",
        "Check Amount", "Reason"]] +
    @checks.map do |check|
      check_amount = check.check_amount.blank? ? '' : sprintf("%.2f", check.check_amount)
      job = check.job
      batch = check.batch
      batchid_array = batch.batchid.split('_') unless batch.batchid.blank?
      bank_batch_number = batchid_array[2]
      deposit_date_for_filename = (@deposit_date.blank? ? '' : @deposit_date.strftime("%Y%m%d"))
      job_image_name_formatted = job.initial_image_name.gsub(/^[0]*/,"")
      renamed_image_file_name = @batch_lockbox + deposit_date_for_filename + job_image_name_formatted

      [ "#{@deposit_date_formatted}", "#{renamed_image_file_name}",
        "#{@batch_lockbox}", "#{bank_batch_number}",
        "#{check.transaction_id}", "$#{check_amount}",
        "#{job.rejected_comment}"
      ]
    end
  end

end