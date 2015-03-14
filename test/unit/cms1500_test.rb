require File.dirname(__FILE__) + '/../test_helper'

class Cms1500servicelinesDDTest < ActiveSupport::TestCase
  # Have to load all these fixtures to accomodate foreign key relationships.
  # TODO: Reconsider enforcement of FK relationships.
  fixtures :shifts, :users, :clients, :facilities, :payers, :batches, :jobs, :cms1500s, :cms1500servicelines, :isa_identifiers
  
  # Test the creation of an 837 from a single CMS 1500 entry
  # disabling this test due to non-existent tables for :cms1500s, :cms1500servicelines
  def ntest_single_837
    @cms1500s = []
    @cms1500s << cms1500s(:cms1500s_096)
    offset = 0
    @isa = isa_identifiers(:isa_1)
    id_837=@isa.isa_number + 1
    template = ERB.new(File.open(File.dirname(__FILE__) + '/../../app/views/admin/batch/837.txt.erb').read)
    output = template.result(binding)
    
    # Delete any trailing spaces in the output
    output.gsub!(/\s+$/, '')
    # Appending newline to match.
    # TODO: Fix gsub() above so that it doesn't remove final newlines
    output << "\n"

    File.open(File.dirname(__FILE__) + '/../output/single_837.txt', 'w') do |f|
      f.puts output
    end
    
    expected = ''
    File.open(File.dirname(__FILE__) + '/../expected/single_837.txt', 'r') do |f|
      expected = f.read
    end

    # Substitute current date and time into expected string so there isn't a mismatch
    expected.gsub!('20080331', Time.now().strftime('%Y%m%d'))
    expected.gsub!('152221', Time.now().strftime('%H%M%S'))

    assert_equal expected, output
  end
  
end