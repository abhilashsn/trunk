# A callback exists for every terminal in grammar. Terminals are in all capitals.
#
# Example Usage:
# require 'pp'
# inspect = Proc.new {|h| pp h}
# print_it_all = Hash.new {|h,k| h[k] = inspect}
# X12N835Parser.parse(File.open('test835.txt'), print_it_all)

class X12N835ParseError < StandardError; end

class X12N835Parser

  # Added strip below to address problems with handling line endings.
  def elements(string) string ? string[0..-2].split(@element_separator).map {|s| s.strip} : nil; end
  def raw_line()       @io.gets(@segment_separator);                           end
  def read_line()      value = @lookahead || raw_line; @lookahead=nil; value;  end
  def lookahead()      @lookahead ||= raw_line;                                end
  def peek()           lookahead ? elements(@lookahead).first : nil;           end
  def read_elements()  elements(read_line);                                    end

  def self.parse835(io, callbacks = {})
    header = io.read(106)
    raise X12N835ParseError.new('Unable to read header') unless header.size == 106
    self.new(io, header[105].chr, header[3].chr, callbacks).parse835(header)
  end

  def self.parse837(io, callbacks = {})
    header = io.read(106)
    raise X12N835ParseError.new('Unable to read header') unless header.size == 106
    self.new(io, header[105].chr, header[3].chr, callbacks).parse837(header)
  end

  def initialize(io, segment_sep, element_sep, callbacks)
    @io                = io
    @callbacks         = callbacks
    @segment_separator = segment_sep
    @element_separator = element_sep
    @lookahead         = nil
  end

  # 835 -> HEADER party_id details ADJUSTMENTS TRAILER
  def parse835(first_line) read_header(first_line).read_parties.read_details.read_adjustments.read_trailer; end
  
  # This is very rudimentary.
  def parse837(first_line) read_837_header(first_line).skip_to_trailer.read_837_trailer; end
  

  # HEADER  
  def read_header(first_line)
    header = [elements(first_line)]
    header << read_elements while peek && peek != 'N1'
    raise X12N835ParseError.new('Interchange segment not found')     unless header[0] && header[0].first == 'ISA'
    raise X12N835ParseError.new('Functional group header not found') unless header[1] && header[1].first == 'GS'
    raise X12N835ParseError.new('Transaction set header not found')  unless header[2] && header[2].first == 'ST'
    @callbacks[:header].call(header) if @callbacks[:header]
    self
  end
  
  def read_837_header(first_line)
    header = [elements(first_line)]
    header << read_elements while peek && peek != 'BHT'
    raise X12N835ParseError.new('Interchange segment not found')     unless header[0] && header[0].first == 'ISA'
    raise X12N835ParseError.new('Functional group header not found') unless header[1] && header[1].first == 'GS'
    raise X12N835ParseError.new('Transaction set header not found')  unless header[2] && header[2].first == 'ST'
    @callbacks[:header].call(header) if @callbacks[:header]
    self
  end

  def skip_to_trailer
    other = []
    while peek && peek != nil
      other << read_elements 
#      other<<"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    end
    @callbacks[:other].call(other) if @callbacks[:other]
    self
  end

  # 1000A or 1000B
  def read_party
    party = [read_elements]
    raise X12N835ParseError.new('Truncated file in header Loop 1000') if party.first.nil?
    party << read_elements while ['N3','N4','REF','PER'].include?(peek)
    party
  end

  # party_id  -> PAYER PAYEE | PAYEE PAYER
  def read_parties
    a = read_party
    b = read_party
    payer = [a,b].detect {|x| x.first[1] == 'PR'}
    payee = [a,b].detect {|x| x.first[1] == 'PE'}
    raise X12N835ParseError.new('Invalid Loop 1000 in header') if payer.nil? || payee.nil?
    @callbacks[:payer].call(payer) if @callbacks[:payer]
    @callbacks[:payee].call(payee) if @callbacks[:payee]
    self
  end

  # SERVICE_PAYMENT
  def read_service_payment
    payment = [elements(read_line)]
    payment << read_elements while ['DTM','CAS','REF','AMT','QTY','LQ'].include?(peek)
    @callbacks[:service_payment].call(payment) if @callbacks[:service_payment]
    self
  end

  # service_payments  -> SERVICE_PAYMENT service_payments | SERVICE_PAYMENT
  def read_service_payments
    read_service_payment while peek == 'SVC'
    self
  end  

  # CLAIM_INFO
  def read_claim_info
    info = []
    info << read_elements while peek != 'SVC'
    @callbacks[:claim_info].call(info) if @callbacks[:claim_info]
    self
  end

  # claim_payment     -> CLAIM_INFO service_payments
  def read_claim_payment
    read_claim_info.read_service_payments
    self
  end

  # claim_payments    -> claim_payment claim_payments | claim_payment
  def read_claim_payments    
    read_claim_payment while peek == 'CLP'
    self
  end

  # DETAIL_HEADER
  def read_detail_header
    header = []
    header << read_elements while peek != 'CLP'
    @callbacks[:detail_header].call(header) if @callbacks[:detail_header]
    self
  end

  # detail            -> DETAIL_HEADER claim_payments
  def read_detail
    read_detail_header.read_claim_payments
    self
  end

  # details           -> detail details | detail
  def read_details
    read_detail while peek == 'LX'
    self
  end

  # ADJUSTMENTS
  def read_adjustments
    adjustments = []
    adjustments << read_elements while peek == 'PLB'
    @callbacks[:adjustments].call(adjustments) if @callbacks[:adjustments] && !adjustments.empty?
    self
  end

  
  # TRAILER
  # TODO: Fix this to handle multiple ST/SE groups
  def read_837_trailer
    trailer = []
    2.times {trailer << read_elements} 
    # raise X12N835ParseError.new('Transaction Set Trailer not found')  unless trailer[0] && trailer[0].first == 'SE'
   # raise X12N835ParseError.new('Functional Group Trailer not found') unless trailer[0] && trailer[0].first == nil
   # raise X12N835ParseError.new('Interchange Trailer not found')      unless trailer[1] && trailer[1].first == nil
    @callbacks[:trailer].call(trailer) if @callbacks[:trailer]
    self
  end

  # TRAILER
  # TODO: Fix this to handle multiple ST/SE groups
  def read_trailer
    trailer = []
    3.times {trailer << read_elements} 
    raise X12N835ParseError.new('Transaction Set Trailer not found')  unless trailer[0] && trailer[0].first == 'SE'
    raise X12N835ParseError.new('Functional Group Trailer not found') unless trailer[1] && trailer[1].first == nil
    raise X12N835ParseError.new('Interchange Trailer not found')      unless trailer[2] && trailer[2].first == nil
    @callbacks[:trailer].call(trailer) if @callbacks[:trailer]
    self
  end
end