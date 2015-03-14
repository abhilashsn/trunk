require 'erb'

#Represents an PcPrint document
class OutputPcPrint::Document
  attr_reader :check, :facility, :batchids, :eob

  include OutputPcPrint::TemplateVariableTranslations

  def initialize(eob, conf = {})
    @eob = eob
    @check = eob.check_information
    @facility = check.batch.facility
    batchid = check.batch.id
    @batchids = [batchid]
  end

  def unknown
    'unkwn'
  end

  def dont_have
    '0.00'
  end

  def ignore
    ''
  end
  def zero
    0
  end

  def pending
    'PN!'
  end

  def generate
    text = ''
    ERB.new(template,0).result(bind { text })
  end

  def bind
    binding
  end

  def template
    IO.read(File.dirname(__FILE__) + '/template.txt.erb')
  end

  def pad_left(txt, total_length = 8)
    pad_amount = total_length - txt.to_s.length
    (' ' * pad_amount) + txt.to_s
  end

  def pad_right(txt, total_length = 41)
    pad_amount = total_length - txt.to_s.length
    txt.to_s + (' ' * pad_amount)
  end

  def center(txt, width = 80)
    margin = ' ' * ((width - txt.to_s.length)/2)
    margin + txt.to_s + margin
  end

end