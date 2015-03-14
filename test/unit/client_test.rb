require File.dirname(__FILE__) + '/../test_helper'

class ClientTest < ActiveSupport::TestCase
  fixtures :clients

  # List of tests
  # 1. Empty client create
  # 2. Create with invalid data
  #   - Check with nil name
  #   - Check with nil tat
  #   - Check Uniqueness of name
  # 3. Test to_s method

  #Blank clent
  def test_blank_client
    client=Client.new
    assert_equal(false,client.save)
  end

  #Test with uniqueness of name
  def test_uniqueness_of_name
    client = Client.new(:name => "XXX", :tat => 14,
      :partener_bank_group_code => 'KK', :internal_tat => 90, :group_code => 'JO',
      :max_jobs_per_user_payer_wise => 5, :max_jobs_per_user_client_wise => 5,
      :max_eobs_per_job => 5)
    assert_equal(false,client.save)
  end

  #Test to_s method
  def test_to_s
    client = clients(:Apria)
    assert_equal client.to_s, client.name, "they match"
  end

  #Test with presence of name
  def test_presence_of_name
    client = Client.new(:tat => 13, :partener_bank_group_code => 'HJ',
      :internal_tat => 89, :group_code => 'JO',:max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Name can't be blank!")
  end

  #Test with presence of tat
  def test_numericality_of_tat
    client = Client.new(:name => "RAM", :partener_bank_group_code => 'HJ',
      :internal_tat => 89, :group_code => 'JO', :max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5, :max_eobs_per_job => 5, :tat => "gh")
    assert_equal(false, client.save, "TAT can't be blank!")
  end

  #Test with presence of internal_tat
  def test_numericality_of_internal_tat
    client = Client.new(:name => "MVG", :partener_bank_group_code => 'HJ',
      :tat => 89, :group_code => 'LP', :max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5, :max_eobs_per_job => 5, :internal_tat => "hj")
    assert_equal(false, client.save, "Internal TAT can't be blank!")
  end

  #Test with presence of partener_bank_group_code
  def test_presence_of_partener_bank_group_code
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22,
      :group_code => 'JO', :max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Internal TAT can't be blank!")
  end

  #Test with numericality of max_eobs_per_job
  def test_numericality_of_max_eobs_per_job
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22,
      :max_eobs_per_job => "yu", :partener_bank_group_code => 'HJ',
      :group_code => 'JO', :max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5)
    assert_equal(false, client.save, "Max# eobs per job is not a number!")
  end

  #Test with numericality of max_jobs_per_user_payer_wise
  def test_numericality_of_max_jobs_per_user_payer_wise
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22, 
      :max_jobs_per_user_payer_wise => "yu", :partener_bank_group_code => 'HJ',
      :group_code => 'JO', :max_jobs_per_user_client_wise => 15, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Max# Jobs Per User Payer Wise is not a number!")
  end

  #Test with numericality of max_jobs_per_user_client_wise
  def test_numericality_of_max_jobs_per_user_client_wise
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22, 
      :max_jobs_per_user_client_wise => "jk", :group_code => 'JO',
      :partener_bank_group_code => 'HJ', :max_jobs_per_user_payer_wise => 5, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Max# Jobs Per User Client Wise is not a number!")
  end

  #Test with presence of group_code
  def test_presence_of_group_code
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22,
      :partener_bank_group_code => 'HJ', :max_jobs_per_user_payer_wise => 5,
      :max_jobs_per_user_client_wise => 5, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Group Code can't be blank!")
  end

  #Test with negative value - max_jobs_per_user_client_wise
  def test_numericality_of_max_jobs_per_user_client_wise
    client = Client.new(:name => "MVG", :internal_tat => 11 , :tat => 22,
      :max_jobs_per_user_client_wise => -56, :group_code => 'JO',
      :partener_bank_group_code => 'HJ', :max_jobs_per_user_payer_wise => 5, :max_eobs_per_job => 5)
    assert_equal(false, client.save, "Max# Jobs Per User Client Wise should be greater than or equal to zero!")
  end
end
