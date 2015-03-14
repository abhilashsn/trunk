class CrTransaction < ActiveRecord::Base
  belongs_to :ach_file
  belongs_to :aba_dda_lookup

  STATUSES_ORDERED = ['Unidentified Site', 'Both', 'Unidentified Payer']
  
  scope :exceptions, where("status IS NOT NULL").joins(:ach_file).order("ach_files.file_arrival_date DESC")

  # Returns a case statement for ordering by a particular set of strings
  # Note that the SQL is built by hand and therefore injection is possible,
  # however since we're declaring the priorities in a constant above it's
  # safe.
  def self.order_by_case
    ret = "CASE"
    STATUSES_ORDERED.each_with_index do |p, i|
      ret << " WHEN status = '#{p}' THEN #{i}"
    end
    ret << " END"
  end

  scope :by_status, :order => order_by_case

  def self.update_payer_status(company_id)
    cr_transactions = CrTransaction.where(:company_id => company_id)
    cr_transactions.each do |crt|
      if crt.status == "Both"
        crt.update_attributes(:status => "Unidentified Site")
      else
        crt.update_attributes(:status => nil)
      end
    end
  end
  
  def self.update_site_status(aba_dda_lookup, trigger)
    cr_transactions = CrTransaction.where(:aba_dda_lookup_id => aba_dda_lookup.id)
    case trigger
    when "remove"
      cr_transactions.each do |crt|
        if crt.status == "Both"
          crt.update_attributes(:status => "Unidentified Payer")
        else
          crt.update_attributes(:status => nil)
        end
      end
    when "add"
      cr_transactions.each do |crt|
        if crt.status == "Unidentified Payer"
          crt.update_attributes(:status => "Both")
        else
          crt.update_attributes(:status => "Unidentified Site")
        end
      end
    end
  end

end
