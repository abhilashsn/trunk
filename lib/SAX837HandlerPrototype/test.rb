require 'rubygems'
require 'nokogiri'
require 'yaml'

include Nokogiri

class SAX837Handler < XML::SAX::Document
	attr_reader :stack, :cnf, :qlf, :val, :is_open
	
	def initialize
		@stack = []
		@grp = ""
		@is_open = false
		@actv_grp = "GENERAL"
		@qlf = "GENERAL"
    @cnf = YAML::load(File.open("test.yml"))
	end
	
  def start_element(element, attributes)
  	open_stack(element)  	
		@actv_grp = element if element.start_with?("GROUP")
  end
  
	def characters(string)
		@val = string
	end

  def end_element(element)
  	secure_data(element)
  	close_stack(element)
	end
	
	def open_stack(element)
  	# Element GROUP_2 open the claim stack
		case element
  		when "GROUP_2"
  			@is_open = true unless is_open
  		when "GROUP_9"
				stack.push ["CLAIM_SERVICE", 1]
			end
	end
	
	def close_stack(element)
  	# Element GROUP_2 close the claim stack
		case element
			when "GROUP_3", "GROUP_6", "GROUP_8"
				reset_qualifier
			when "GROUP_2"
  			flush_stack
  	end
	end
	
	def secure_data(element)
    return unless is_open 
# puts "ST! " +  @grp + " " + @qlf+ " " + element	
		key = @cnf[@grp + @qlf][element] rescue return
		return if key.nil?
# puts  @grp + " " + @qlf + "  " + key.to_s + " " + element	
		if key.eql?("/qualifier")
			@qlf = @val 
			@grp = @actv_grp
		else
			stack.push [key, @val] 
		end
	end

	def flush_stack
		puts stack.inspect
		stack.clear
		@is_open = false
	end
	
	def reset_qualifier
		@grp = ""
		@qlf = "GENERAL"
		@actv_grp = "GENERAL"
	end
	
end

s = Time.now.to_f
callback = SAX837Handler.new
parser = XML::SAX::Parser.new(callback)
# parser.parse_file("NYO9MSGY.048.#0322396.xml")
# parser.parse_file("10781.x12.xml")
parser.parse_file("10832.x12.xml")
# callback.show_stack
e = Time.now.to_f
puts e-s
