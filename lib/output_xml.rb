##################################################################################################################################
#   Description: Common methods required for XML creation module.
#
#   This class contains following methods.
#   * self.log: Creates log file.
#
#   Created   : 2010-06-18 by Rajesh R @ Revenuemed
#
##################################################################################################################################

module OutputXml
  require 'utils/rr_logger'

  #----------------------------------------------------
  # Description  : Created log file
  # Input        : None.
  # Output       : Logger object.
  #----------------------------------------------------
  def self.log
    RevRemitLogger.new_logger(LogLocation::XOPLOG)
  end
end
