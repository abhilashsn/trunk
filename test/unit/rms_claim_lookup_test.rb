require 'test_helper'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock
end

class RmsClaimLookupTest < ActiveSupport::TestCase
  context "invalid credentials" do
    setup do
      VCR.use_cassette('invalid_credentials') do
        @good_pw = RmsClaimLookup.default_params[:pw]
        RmsClaimLookup.default_params[:pw] = "foo"
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 106)
      end
    end

    teardown do
      RmsClaimLookup.default_params[:pw] = @good_pw
    end

    should "have return code 403" do
      assert_equal 403, @result.response_code
    end
  end

  context "invalid PID" do
    setup do
      VCR.use_cassette('invalid_pid') do
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 80)
      end
    end

    should "have return code 401" do
      assert_equal 401, @result.response_code
    end
  end

  context "a PAN match" do
    setup do
      VCR.use_cassette('pan_match') do
        @result = RmsClaimLookup.search(:patient_no => "03099791", :pid => 106)
      end
    end

    should "have return code 200" do
      assert_equal 200, @result.response_code
    end

    should "match query" do
      assert_equal "03099791", @result.mpi_results.first.patient_account_number
    end

    should "have primary and secondary claims" do
      assert_equal 2, @result.mpi_results.length
    end
  end

  context "no PAN match" do
    setup do
      VCR.use_cassette('no_pan_match') do
        @result = RmsClaimLookup.search(:patient_no => "03099792", :pid => 106)
      end
    end

    should "have return code 404" do
      assert_equal 404, @result.response_code
    end

    should "have no claims" do
      assert_equal 0, @result.mpi_results.length
    end
  end

  context "multiple claims were found, none were acceptable" do
    setup do
      VCR.use_cassette('multiple_claims_none_acceptable') do
        @result = RmsClaimLookup.search(:pid => "106", :patient_lname => "ARMSTRONG", :date_of_service_from => "02/08/10", :total_charges => "4973.93")
      end
    end

    should "have return code 406" do
      assert_equal 406, @result.response_code
    end
  end

  context "other match" do
    setup do
      VCR.use_cassette('other_match') do
        @result = RmsClaimLookup.search(:pid => "106", :patient_fname => "SANDRA", :patient_lname => "ARMSTRONG", :date_of_service_from => "02/08/10", :total_charges => "4973.93")
      end
    end

    should "have return code 200" do
      assert_equal 200, @result.response_code
    end

    should "match query" do
      assert_equal "SANDRA", @result.mpi_results.first.patient_first_name
      assert_equal "ARMSTRONG", @result.mpi_results.first.patient_last_name
      assert_equal "2010-02-08", @result.mpi_results.first.claim_statement_period_start_date.to_s
    end

    should "have primary and secondary claims" do
      assert_equal 2, @result.mpi_results.length
    end
  end

  context "missing optional fields" do
    setup do
      VCR.use_cassette('missing_optional_fields') do
        @result = RmsClaimLookup.search(:pid => "106", :patient_lname => "ARMSTRONG", :date_of_service_from => "02/08/10")
      end
    end

    should "have return code 400" do
      assert_equal 400, @result.response_code
    end
  end
end