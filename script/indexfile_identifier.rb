require 'csv'
require 'nokogiri'
require File.expand_path(File.dirname(__FILE__)) + '/../config/initializers/rr_date'

class IndexfileIdentifier
    
  DateConfiguration = {:csv => {'ahn' => [4, 1], 'albert_einstein_college_of_medicine' => [4, 1], 'apria' => [3, 2],
     'boa' => [5, 3], 'caris_diaognostics' => [5, 1], 'caris_diaognostics_do' => [5, 1], 'caris_molecular_profiling_institute' => [5, 1],
     'clinical_reference_laboratory' => [0], 'cohen_dermatopathology' => [5, 1], 'general_emergency_medical_specialis' => [2, 1],
     'goodman_campbell_brain_and_spine' => [0, 0, "%m%d%Y"], 'insight_health_corp' => [7, 1], 'jpmc' => [0, 0, "%m%d%Y"], 'jpmc_single' => [0, 0, "%m%d%Y"],
     'kettering_pathology_assoc' => [4, 1], 'medassets' => [4, 1], 'metroplex_pathology_assoc' => [5, 1], 'navicure' => [4, 1],
     'optim_healthcare' => [0], 'pathology_consultants_llc' => [0, 1], 'pathology_medical_services' => [4], 'pnc' => [5, 3],
     'stanford_university_medical_center' => [5, 1], 'ucb' => [0], 'pacific_dental_services' => [4,1],'univ_hosp_lab_svc_foundation' => [2, 1], 'wellstar_laboratory_services' => [5, 1],
     'wellsfargo' => [1, 0], 'barnabas' => [0, 0, "%m%d%Y"]
     },
     :xml => {'medistreams' => ['//depositdate'], 'american_health_network' => ['//@ICLDate', "%m%d%Y"], 'mercy_health_partners' => ["//Fld[@ID='Deposit_Date']", "%m/%d/%Y"] },
     :dat => { 'atlanticar_clinical_lab' => [ 24, 31, "%Y%m%d"], 'wachovia' =>  [24, 31, "%Y-%m-%d"]},
     :asc => {'general' => [ 8, 8,"%m/%d/%y" ]},
     :txt => {'general' => [ 68, 73,  "%y%m%d"]},
     :idx => {'general' => [ 1, 8, "%Y-%m-%d"]}
 }

  def initialize facility, client
    @facility = facility
    @client = client
  end

  def find_index_file
    @index_ext = @facility['index_file_format'].to_s.downcase
    @index_parser = @facility['index_file_parser_type'] ? @facility['index_file_parser_type'].gsub('_bank', '').downcase : nil
    @index_ext = 'csv' if @index_parser == 'wellsfargo'
    @fac_sym = @facility['name'].to_s.to_file
    @client_sym = @client['name'].to_s.to_file
    send(method_to_call)
  end

  def parse_index_file unzip_loc
    send("parse_#{@index_ext}_file", unzip_loc)
  end

  def parse_csv_file unzip_loc
    col_sep =  (@index_parser == 'wellsfargo') ? '|' : ','
    index_file = Dir.glob("#{unzip_loc}/*", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:csv][@index_parser] || DateConfiguration[:csv][@fac_sym] || DateConfiguration[:csv][@client_sym]
    if date_location
      @csv = CSV.read(index_file, :col_sep => col_sep)
      headers = @csv.shift(date_location[1].to_i)
      if @csv.flatten.empty?
        @csv = [headers[1]]
        date_location = [4]
      end
      date = (date_location[2] ? Date.strptime(parse(date_location[0]), date_location[2]) : Date.rr_parse(parse(date_location[0]), true))
    else
      Date.today.to_s
    end
  end

  def parse location
    @csv[0][location]
  end

  def parse_xml_file unzip_loc
    index_file = Dir.glob("#{unzip_loc}/*.xml", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:xml][@fac_sym] || DateConfiguration[:xml][@client_sym] 
    doc = Nokogiri::XML(File.open(index_file))
    date_tag = doc.xpath(date_location[0]).first if date_location
    if date_tag
      date = date_location[1] ? Date.strptime(date_tag.text, date_location[1]) : Date.rr_parse(date_tag.text, true) rescue nil
    end
    date || Date.today.to_s
  end

  def parse_orboidx_file unzip_loc
    Date.today.to_s
  end


  def parse_dat_file unzip_loc
    index_file = Dir.glob("#{unzip_loc}/*", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:dat][@index_parser] || DateConfiguration[:dat][@fac_sym]
    if date_location
      dat =  File.readlines(index_file)
      dat.delete_if{|x| x.to_s.empty?}
      date_string = dat[0][date_location[0]..date_location[1]].to_s.strip
      date = Date.rr_parse(date_string, true).strftime(date_location[2])
    else
      Date.today.to_s
    end
  end

  def parse_asc_file unzip_loc
    index_file = Dir.glob("#{unzip_loc}/*.asc", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:asc]['general']
    asc =  File.readlines(index_file)
    asc.delete_if{|x| x.to_s.strip.empty?}
    date_string = asc[0][date_location[0],date_location[1]].to_s.strip
    Date.strptime(date_string, date_location[2])
  end

  def parse_txt_file unzip_loc
    index_file = Dir.glob("#{unzip_loc}/*.txt", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:txt]['general']
    txt =  File.readlines(index_file)
    txt.delete_if{|x| x.to_s.strip.empty?}
    date_string = txt[0][date_location[0],date_location[1]].to_s.strip
    Date.strptime(date_string, date_location[2])
  end

  def parse_idx_file unzip_loc
    index_file = Dir.glob("#{unzip_loc}/*.idx", File::FNM_CASEFOLD).first
    date_location = DateConfiguration[:idx]['general']
    idx =  File.readlines(index_file)
    idx.delete_if{|x| x.to_s.strip.empty?}
    date_string = idx[0][date_location[0],date_location[1]].to_s.strip
    Date.rr_parse(date_string, true).strftime(date_location[2])
  end

  def method_to_call
    parser = @index_parser
    boa_facilities =  ['cohen_dermatopathology', 'metroplex_pathology_asoc', 'caris_molecular_profiling_institute', 'caris_diagnostics',
               'caris_diagnostics_do', 'wellstar_laboratory_services', 'stanford_university_medical_center' ]
    parser = 'boa' if boa_facilities.include? @fac_sym
    method_to_call = "index_files"
    methods =  self.methods
    if methods.include?("#{method_to_call}_#{@fac_sym}".to_sym)
      method_to_call << "_#{@fac_sym}"
    elsif methods.include?("#{method_to_call}_#{@client_sym}".to_sym)
      method_to_call << "_#{@client_sym}"
    elsif parser && methods.include?("#{method_to_call}_#{parser.downcase}".to_sym)
      method_to_call << "_#{parser.downcase}"
    end
    return method_to_call
  end

  def index_files
    "\"*.#@index_ext\""
  end

  def index_files_pnc
    index_files_boa
  end

  def index_files_boa
    '"*summary.csv"' 
  end

  def index_files_insight_health_corp
    "\"*.#@index_ext\" -x **/summary.csv **/corresp.csv **/detail.csv"
  end

  def index_files_jpmc_single
    "\"*.#@index_ext\" \"*index*\""
  end

  def index_files_goodman_campbell
    "\"*.#@index_ext\" \"*index*\""
  end

  def index_files_barnabas
    "\"*.#@index_ext\" \"*index*\""
  end

  def index_files_coug
    '"indexfile.txt"'
  end

end

class String
  def to_file
    self.downcase.gsub(" ", "_")
  end
end