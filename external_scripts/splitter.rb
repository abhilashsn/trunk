#!/usr/bin/env /opt/ruby-enterprise-1.8.7-2010.02/bin/ruby
#!/usr/bin/env ruby 

# == Synopsis 
#   This utility takes a specially formatted CSV file and a multipage TIFF file
#   and splits the single TIFF into a series of smaller TIFF files: one for each
#   check group.
# 
#   By convention, output files will be named based on the original image file name, 
#   the batch number, the sequence within the batch, and whether it is correspondence
#   or EOB, e.g.:
#
#   hss_090130_635_001_e.tif - First check and EOB for batch 635
#   hss_090130_639_002_c.tif - Second correspondence for batch 639
#
# == Examples
#   Splits a multipage TIFF into check/EOB groups based on a CSV file:
#     splitter private/input/TransactionResults_20090130.csv private/input/hss_090130.tif
#
#   Other examples:
#     TBD
#
# == Usage 
#   splitter [options] csv_file image_file
#
#   For help use: splitter -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#
# == Author
#   Coty Rosenblath (crosenblath@revenuemed.com)
#
# == Copyright
#   Copyright (c) 2009 RevenueMed, Inc. 

require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'

require 'rubygems'
gem 'fastercsv', '>= 1.4.0'
require 'fastercsv'

class App
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      process_arguments            
      process_command
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      # TO DO - add verbosity levels
      opts.on('-V', '--verbose')    { @options.verbose = true }  
      opts.on('-q', '--quiet')      { @options.quiet = true }
      # TO DO - add additional options
            
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      # TO DO - implement your real logic here
      true if @arguments.length == 2
    end
    
    # Setup the arguments
    def process_arguments
      @csv_file = @arguments[0]
      @image_file = @arguments[1]
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      csv_file = @csv_file
      output_filename = "output.csv"
      image_file = @image_file
      
      first_page = 0
      
      FasterCSV.open(output_filename, "wb", {:write_headers => :true, :headers => "Remitter,Payment #,Amount,Type,Date,Lockbox,Batch,Item,Gp,Pg,Image Name"}) do |output|
        header = []
        File.readlines(csv_file).collect{|r| r.gsub('"','')}.each_with_index do |line, index|
          row = FasterCSV.parse(line).first
          if index.eql?(0)
            header = row
            next
          end
        
          check_group_pages = row[9].to_i
          last_page = first_page + (check_group_pages - 1)
          page_range = Range.new(first_page, last_page)
          first_page = last_page + 1
          pages = page_range.to_a.join(',')
          base, extension = image_file.split('/').last.split('.')
          item_string = "%03d" % row[7].to_i
          amount = row[2].to_f
          batch_type = amount == 0.0 ? 'c' : 'e'
          destination_file = "#{base}_#{row[6]}_#{item_string}_#{batch_type}.#{extension}"
          destination_path = "#{File.dirname(image_file)}/#{destination_file}"
          command = "tiffcp '#{image_file}',#{pages} '#{destination_path}'"
          puts command if @options.verbose
          result = system(command)
          if !result
            puts "Error running: #{command}"
          end
          
          row[10] = destination_file
          output << row
        end
      end
    end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = App.new(ARGV, STDIN)
app.run
