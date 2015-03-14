require File.dirname(__FILE__)+'/../test_helper'

class DocumentTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :facility_output_configs

  def setup
    @document = Output835::Document.new([check_informations(:check_7)])
    @facility = facilities(:facility_3)
    @fac_config = facility_output_configs(:facility_output_config_9)
  end

  def test_new_batch?
    checks = [check_informations(:check_7),check_informations(:check_48)]
    checks.each do |check|
      assert(@document.new_batch? check)
    end
  end

end