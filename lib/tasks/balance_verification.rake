namespace :balance_verification do

  desc "The task to verify given 835 file is balanced ..."
  task :file_835, [:file_path] => [:environment]  do |t, args|
    file_835_paths = args.file_path ? Dir[args.file_path.to_s + "/**/*.835"] : []

    file_835_results = {}
    file_835_paths.each do |file_835_path|
      file_835 = File.open("#{file_835_path}", 'r')
      @segments = ''
      IO.foreach(file_835){|segment| @segments += segment}
      file_835_contents = @segments.delete("\n").split("~").collect{|line| line.strip+"~\n"}
      delimiter = file_835_contents.first[3]
      file_835_results.merge!(file_835_path => balance_verification(file_835_contents, delimiter))
    end

    print_formatted_results(file_835_results)
  end

  def print_formatted_results(file_835_results)
    file_835_results.each_pair do |file_name, transaction_results|
      file_balanced = transaction_results.flatten.include?(false) ? 'Not Balanced' : 'Balanced'
      puts "+"+"-" * 123 + "+\n" + "|..." + "#{file_name.last(70).justify(97)}"+"|"+file_balanced.justify(22)+"|" + "\n" + "|" + "-" * 123 + "|"
      transaction_results.each do |transaction_result|
        puts "|" + transaction_result.first.justify(100) + "|" + (transaction_result.last ? "Balanced".justify(22) : "Not Balanced".justify(22)) + "|"
      end
     puts "+" + "-" * 123 + "+"
    end
    puts "Total Number of Files Processed : #{file_835_results.count}"
  end

  def balance_verification(file_835_contents, delimiter)
    @transaction_results = []
    file_835_contents.each do |line|
    	case line[0,3]
    	when "ST"+delimiter
    		initialize_transaction_object(line, delimiter)
    	when "BPR"
    		@balance_verification.set_provider_payment_values(line, delimiter)
    	when "CLP"
    		@balance_verification.set_claim_values(line, delimiter)
    	when "SVC"
    		@balance_verification.set_service_values(line, delimiter)
    	when "CAS"
    		@balance_verification.set_claim_service_cas_amounts(line, delimiter)
    	when "PLB"
    		@balance_verification.set_provider_adjustment_values(line, delimiter)
    	when "SE"+delimiter
        @transaction_results << @balance_verification.check_transaction_balance
      end
    end
    @transaction_results
  end

  def initialize_transaction_object(line, delimiter)
    track_number = line.split(delimiter)[2].chop.delete('~')
    @balance_verification = Verify835::BalanceVerification.new(track_number)
  end

end