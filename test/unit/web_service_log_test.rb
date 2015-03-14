require 'test_helper'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

class WebServiceLogTest < ActiveSupport::TestCase
  context "invalid credentials" do
    setup do
      VCR.use_cassette('invalid_credentials') do
        @good_pw = RmsClaimLookup.default_params[:pw]
        RmsClaimLookup.default_params[:pw] = "foo"
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 106)
        @wsl = WebServiceLog.last
      end
    end

    teardown do
      RmsClaimLookup.default_params[:pw] = @good_pw
    end

    should "have return code 403" do
      assert_equal 403, @wsl.response_code
    end
  end

  context "invalid PID" do
    setup do
      VCR.use_cassette('invalid_pid') do
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 80)
        @wsl = WebServiceLog.last
      end
    end

    should "have return code 401" do
      assert_equal 401, @wsl.response_code
    end
  end

  context "a PAN match" do
    setup do
      VCR.use_cassette('pan_match') do
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 106)
        @wsl = WebServiceLog.last
      end
    end

    should "have return code 200" do
      assert_equal 200, @wsl.response_code
    end
  end

  context "no PAN match" do
    setup do
      VCR.use_cassette('no_pan_match') do
        @result = RmsClaimLookup.search(:patient_no => "03099792", :pid => 106)
        @wsl = WebServiceLog.last
      end
    end

    should "have return code 404" do
      assert_equal 404, @wsl.response_code
    end
  end

  context "multiple claims were found, none were acceptable" do
    setup do
      VCR.use_cassette('multiple_claims_none_acceptable') do
        @result = RmsClaimLookup.search(:pid => "106", :patient_lname => "ARMSTRONG", :date_of_service_from => "02/08/10", :total_charges => "4973.93")
        @wsl = WebServiceLog.last
      end
    end

    should "have return code 406" do
      assert_equal 406, @wsl.response_code
    end
  end

  context "missing optional fields" do
    setup do
      VCR.use_cassette('missing_optional_fields') do
        @result = RmsClaimLookup.search(:pid => "106", :patient_lname => "ARMSTRONG", :date_of_service_from => "02/08/10")
        @wsl = WebServiceLog.last
      end
    end

    should "have return code 400" do
      assert_equal 400, @wsl.response_code
    end
  end

  context "a successful search" do
    setup do
      VCR.use_cassette('pan_match') do
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 106)
        @wsl = WebServiceLog.last
      end
    end

    should "have correct service name" do
      assert_equal '/mbx-claim-lookup/LookupClaim', @wsl.service
    end

    should "have correct query" do
      assert_equal '{"pid":106,"pan":"03099791"}', @wsl.query
    end

    should "have non-zero response time" do
      assert_operator 0, :<, @wsl.response_time
    end
  end
end