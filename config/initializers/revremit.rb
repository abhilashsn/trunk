# Boolean flag to identify Bank/Non-Bank deployment
$IS_PARTNER_BAC = Partner.table_exists? && Partner.is_partner_bac?
$APP_TITLE = "Rev Remit"

$HIPAA_CODES = HipaaCode.collect_active_code_details if HipaaCode.table_exists?

# Default Payer Reference
$DEFAULT_PAYER = Payer.where("payer = 'UNKNOWN' and payid = '99999'").first if Partner.table_exists?
Rack::Utils.key_space_limit = 10485760

class String

  def left_padd(total_length, length_to_padd, char)
    unless self.blank?
      padd_length = total_length - self.length
      if padd_length >= length_to_padd
        (char * length_to_padd + self).ljust(15)
      else
        char * padd_length + self
      end
    else
      ""
    end
  end

  def justify(size, character = nil)
    if self.blank?
      ""
    elsif self.length > size
      self[0...size]
    elsif character
      self.rjust(size,character)
    else
      self.ljust(size)
    end
  end

  def to_dollar
    unless self.to_f.zero?
      "%.2f" % self rescue "0"
    else
      '0'
    end
  end

  def to_blank
    self == '0' ? '' : self
  end

  def to_file
    self.downcase.gsub(' ', '_')
  end
  
  #utility function to return true if blank or  if string is "null"
  def rr_blank_or_null?
    self.blank? || self == "null"
  end

  def xmlize
    self.gsub(/[&"'><]/, { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;', "'" => '&apos;' })
  end

end

class NilClass
  def rr_blank_or_null?
    self.blank?
  end

  def xmlize
  end
end


class Hash
  #-----------------------------------------------------------------------------
  # Description : This method converts a hash into a string of hash values each is
  #               seperated by '*'.
  # Input       : hash
  # Output      : string
  #-----------------------------------------------------------------------------
  def segmentize
    self.keys.sort.collect { |k| self[k].to_s }.flatten.compact
  end

  #-----------------------------------------------------------------------------
  # Description : This method is to convert string keys of a hash into integer
  #               keys.
  # Input       : hash
  # Output      : hash
  #-----------------------------------------------------------------------------
  def convert_keys
    result = Hash.new
    self.each{|k,v| result[k.to_i] = v}
    result
  end

end

class Array

  #-----------------------------------------------------------------------------
  # Description : This method is for converting array elements into string
  # Input       :
  # Output      : converted array
  #-----------------------------------------------------------------------------
  def to_string
    self.collect{|elem| elem.to_s}
  end
end
