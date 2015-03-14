require 'erb'

#Represents a Nextgen document
class OutputNextgen::Document
  attr_reader :checks, :check, :batch, :eob

  include OutputNextgen::TemplateVariableTranslations

  def initialize(checks, conf = {})
    @batch = checks.first.batch
    @checks = checks
  end

  def generate
    ERB.new(File.open(template).read).result(binding)
  end

  def template
    File.dirname(__FILE__) + '/template.txt.erb'
  end

  def eob_count
    check_ids = @checks.map(&:id)
    eob_count = 0
    if !check_ids.blank?
      eob_count = PatientPayEob.count(:conditions => ["check_information_id in (#{check_ids.join(',')})"])
    end
    eob_count
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end

  # Recieves 'amount' which is a dollar amout.
  # Returns the amount in cents, in string format
  def to_cents(amount)
    amount.blank? ? '0' : (amount * 100).to_i.to_s
  end
  
  def pad_left(txt, total_length, char = ' ')
    txt.to_s.rjust(total_length, char)
  end

  def pad_right(txt, total_length, char = ' ')
    txt.to_s.ljust(total_length, char)
  end

  def fill_zeroes(count, str)
    str.rjust(count, '0')
  end

  def fill_spaces(count)
    str = ''
    str.ljust(count, ' ')
  end
end