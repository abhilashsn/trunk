require 'nokogiri'
require 'yaml'

class Transformer_837
  attr_reader :doc, :log, :cnf

  def initialize(xml,cnf)
    @doc = Nokogiri::XML(File.open(xml))
    @log = Logger.new('837Transform.log')
    @cnf = YAML::load(File.open(cnf))
  end

  def transform
    log.info ">>Base Transformation Starts " + Time.now.to_s
      doc.xpath(cnf["ITERATORS"]["I837"]).each do |e|
        log.info "Number of claims: #{e.xpath(cnf["ITERATORS"]['ICLM']).count()}"
        e.xpath(cnf["ITERATORS"]["ICLM"]).each do |clms|
          clm = process_claim(clms)
          ci = 0

          clms.xpath(cnf["ITERATORS"]["ICLM_ITM"]).each do |clmitms|
            clm_itms = process_claim_itms(clmitms)
            clm.claim_service_informations << clm_itms
            ci = ci + 1
          end # clmitms
          
          log.info " .... Claim itmes: #{ci}"
          clm.save
        end #clms
      end # doc
    
    log.info ">>Base Transformation Ends" + Time.now.to_s
  end

  protected
  
  def process_claim clms
    clm = ClaimInformation.new
    cnf["CLAIM"].each { |k,v| clm[k] = clms.xpath(v).text }
    return clm
  end
 
  def process_claim_itms clmitms
    clm_items = ClaimServiceInformation.new
    cnf["CLAIM_ITMS"].each { |k,v| clm_items[k] = clmitms.xpath(v).text }
    return clm_items
  end
  
end #class
